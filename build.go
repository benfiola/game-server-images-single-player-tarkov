package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"regexp"
	"runtime"
	"strconv"
	"strings"

	"github.com/google/go-github/v63/github"
)

const (
	RepoLegacy = "sp-tarkov/server"
	RepoCSharp = "sp-tarkov/server-csharp"
)

type Version struct {
	major int
	minor int
	patch int
	tag   string
}

func parseVersion(tag string) (*Version, error) {
	tag = strings.TrimPrefix(tag, "v")

	re := regexp.MustCompile(`^(\d+)\.(\d+)\.(\d+)`)
	matches := re.FindStringSubmatch(tag)
	if len(matches) < 4 {
		return nil, fmt.Errorf("invalid version format: %s", tag)
	}

	major, _ := strconv.Atoi(matches[1])
	minor, _ := strconv.Atoi(matches[2])
	patch, _ := strconv.Atoi(matches[3])

	return &Version{
		major: major,
		minor: minor,
		patch: patch,
		tag:   tag,
	}, nil
}

func (v *Version) String() string {
	return fmt.Sprintf("v%d.%d.%d", v.major, v.minor, v.patch)
}

func (v *Version) Repo() string {
	if v.major >= 4 {
		return RepoCSharp
	}
	return RepoLegacy
}

func (v *Version) IsCSharp() bool {
	return v.major >= 4
}

func compareVersions(v1, v2 *Version) int {
	if v1.major != v2.major {
		return v1.major - v2.major
	}
	if v1.minor != v2.minor {
		return v1.minor - v2.minor
	}
	return v1.patch - v2.patch
}

func getLatestTag(ctx context.Context, client *github.Client, repo string) (*Version, error) {
	parts := strings.Split(repo, "/")
	owner := parts[0]
	name := parts[1]

	tags, _, err := client.Repositories.ListTags(ctx, owner, name, &github.ListOptions{PerPage: 50})
	if err != nil {
		return nil, fmt.Errorf("failed to get tags for %s: %w", repo, err)
	}

	if len(tags) == 0 {
		return nil, fmt.Errorf("no tags found for %s", repo)
	}

	// Find the latest stable release (no RC, alpha, beta, or pre-release tags)
	stableRe := regexp.MustCompile(`^\d+\.\d+\.\d+$`)
	var latestVersion *Version

	for _, tag := range tags {
		tagName := tag.GetName()
		if !stableRe.MatchString(tagName) {
			continue // Skip RC, pre-release, or build-metadata tags
		}

		version, err := parseVersion(tagName)
		if err != nil {
			continue
		}

		if latestVersion == nil || compareVersions(version, latestVersion) > 0 {
			latestVersion = version
		}
	}

	if latestVersion == nil {
		return nil, fmt.Errorf("no stable releases found for %s", repo)
	}

	return latestVersion, nil
}

func detectArch() string {
	return runtime.GOARCH
}

func validateArch(arch string) error {
	switch arch {
	case "amd64", "arm64":
		return nil
	default:
		return fmt.Errorf("unsupported architecture: %s (must be amd64 or arm64)", arch)
	}
}

func getScriptPath(version *Version, arch string) (string, error) {
	if !version.IsCSharp() {
		// Legacy (Node.js) - same script for both architectures
		return "scripts/build-legacy.sh", nil
	}

	// C# / .NET - architecture-specific scripts
	switch arch {
	case "amd64":
		return "scripts/build-csharp-amd64.sh", nil
	case "arm64":
		return "scripts/build-csharp-arm64.sh", nil
	default:
		return "", fmt.Errorf("unsupported architecture for C# build: %s", arch)
	}
}

func checkVersions(ctx context.Context, client *github.Client) error {
	legacyVersion, err := getLatestTag(ctx, client, RepoLegacy)
	if err != nil {
		log.Printf("warning: failed to get legacy version: %v", err)
	}

	csharpVersion, err := getLatestTag(ctx, client, RepoCSharp)
	if err != nil {
		log.Printf("warning: failed to get csharp version: %v", err)
	}

	output := map[string]string{}
	if legacyVersion != nil {
		output["legacy"] = legacyVersion.String()
	}
	if csharpVersion != nil {
		output["csharp"] = csharpVersion.String()
	}

	jsonBytes, err := json.Marshal(output)
	if err != nil {
		return fmt.Errorf("failed to marshal JSON: %w", err)
	}
	fmt.Println(string(jsonBytes))

	return nil
}

func buildSPT(version string, arch string, outputDir string) error {
	v, err := parseVersion(version)
	if err != nil {
		return fmt.Errorf("invalid version: %w", err)
	}

	// Use provided arch or default to current system
	if arch == "" {
		arch = detectArch()
	}

	if err := validateArch(arch); err != nil {
		return err
	}

	repo := v.Repo()
	repoURL := fmt.Sprintf("https://github.com/%s", repo)

	buildType := "legacy"
	if v.IsCSharp() {
		buildType = "csharp"
	}

	log.Printf("Building %s (%s) from %s [arch: %s]", v, buildType, repo, arch)

	tempDir, err := os.MkdirTemp("", "spt-build-*")
	if err != nil {
		return fmt.Errorf("failed to create temp dir: %w", err)
	}
	defer os.RemoveAll(tempDir)

	// Clone the repository
	cmd := exec.Command("git", "clone", "--depth", "1", "--branch", v.String(), repoURL, tempDir)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to clone %s: %w", repo, err)
	}

	// Get the appropriate build script
	scriptPath, err := getScriptPath(v, arch)
	if err != nil {
		return fmt.Errorf("failed to get build script: %w", err)
	}

	// Ensure script is executable
	if err := os.Chmod(scriptPath, 0755); err != nil {
		return fmt.Errorf("failed to make script executable: %w", err)
	}

	// Execute the build script
	log.Printf("Executing %s", scriptPath)
	cmd = exec.Command(scriptPath, tempDir, v.String(), outputDir)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("build script failed: %w", err)
	}

	log.Printf("Build completed: %s", outputDir)
	return nil
}

func main() {
	ctx := context.Background()

	checkCmd := flag.NewFlagSet("check", flag.ExitOnError)

	buildCmd := flag.NewFlagSet("build", flag.ExitOnError)
	buildVersion := buildCmd.String("version", "", "Version to build")
	buildArch := buildCmd.String("arch", "", "Architecture (amd64 or arm64, defaults to current system)")
	buildOutput := buildCmd.String("output", "./dist", "Output directory")

	if len(os.Args) < 2 {
		fmt.Fprintf(os.Stderr, "usage: %s <check|build> [options]\n", os.Args[0])
		os.Exit(1)
	}

	switch os.Args[1] {
	case "check":
		checkCmd.Parse(os.Args[2:])

		client := github.NewClient(nil)
		if err := checkVersions(ctx, client); err != nil {
			log.Fatal(err)
		}

	case "build":
		buildCmd.Parse(os.Args[2:])
		if *buildVersion == "" {
			log.Fatal("--version required")
		}

		if err := buildSPT(*buildVersion, *buildArch, *buildOutput); err != nil {
			log.Fatal(err)
		}

	default:
		fmt.Fprintf(os.Stderr, "unknown command: %s\n", os.Args[1])
		os.Exit(1)
	}
}

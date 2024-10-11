package gnopedia

import (
	fmt "gno.land/p/demo/ufmt"
	"strconv"
	"strings"
)

const (
	NOT_FOUND_ERROR = "404 Not Found"
)

func Render(path string) string {
	if path != "" {
		return renderRoute(path)
	}

	var sb strings.Builder
	sb.WriteString(`
<style>
table, th, td {
  border: 1px solid black;
}
</style>
`)

	articles.ReverseIterate(0, 0, func(_ uint64, value interface{}) bool {
		article, ok := value.(*Article)
		if !ok {
			panic("not an article value in storage")
		}
		idString := strconv.FormatUint(article.ID, 10)
		sb.WriteString("---\n## ")
		sb.WriteString("[" + article.Title + "](/r/foundations/gnopedia:articles/" + idString + ")\n\n")

		// Article don't have yet published version
		if article.CurrentVersion < 0 {
			sb.WriteString(fmt.Sprintf("> No content was voted to be approved yet. "+
				"Has %d version pending, click on article to vote for the new version", len(article.Versions)))
			return false
		}

		sb.WriteString(article.Versions[article.CurrentVersion].Text)
		return false
	})

	return sb.String()
}

func renderRoute(path string) string {
	if strings.HasPrefix(path, "articles/") {
		parts := strings.Split(path, "/")
		if len(parts) != 2 {
			return NOT_FOUND_ERROR
		}

		articleID, err := strconv.Atoi(parts[1])
		if err != nil {
			return "Invalid article ID: " + parts[1]
		}

		art := getArticle(uint64(articleID))
		return renderArticle(art)
	}
	return NOT_FOUND_ERROR
}

func renderArticle(article *Article) string {

	var sb strings.Builder
	sb.WriteString(`
<style>
table, th, td {
  border: 1px solid black;
}
</style>
`)

	sb.WriteString(fmt.Sprintf("# %s\n\n", article.Title))

	// Situation when the article has no content yet to be approved
	if article.CurrentVersion < 0 {
		sb.WriteString(fmt.Sprintf("> **No content was voted to be approved yet.\n"+
			"Has %d versions pending**\n\n", len(article.Versions)))

		sb.WriteString(renderPendingVersions(article))
		return sb.String()
	}

	// Situation when article version that published is in disprove by the late voters
	// (they were yelling misinformation, misinformation and voting with taxpayer hard money)
	if article.CurrentVersionInDisprove {
		sb.WriteString(fmt.Sprintf("\n>%s\n", "Article was voted to be in disprove status, "+
			"please do additional fact-check or propose changes for the article to make it better"))
	}

	// Situation when the article has content
	sb.WriteString(article.Versions[article.CurrentVersion].Text)
	ver := article.Versions[article.CurrentVersion]
	// Still allow to vote for the current version of the article have additional rewards or require changes
	//
	// TODO: Show to the user information if his/she's/theirs/nnnn vote already in for one of the sides
	// at this moment this information is hidden
	approveText := fmt.Sprintf("`use the` </br>```gnokey maketx call -pkgpath \"gno.land/r/foundations/gnopedia\" ApproveArticleVersion -args %d -args %d```", article.ID, ver.VersionID)
	denyText := fmt.Sprintf("`use the` </br>```gnokey maketx call -pkgpath \"gno.land/r/foundations/gnopedia\" DenyArticleVersion -args %d -args %d```", article.ID, ver.VersionID)
	sb.WriteString(col2WithTitle("👍", approveText, "👎", denyText))

	// Situation when there are available versions to vote for the article to be improved
	if isPendingVersionAvailable(article) {
		sb.WriteString("\n\n---\n\n ### Pending versions for this article\n\n")
		sb.WriteString(renderPendingVersions(article))
	}

	return sb.String()
}

func renderPendingVersions(article *Article) string {
	var sb strings.Builder
	// Set the current staged version to zero or current article version
	atVersion := article.CurrentVersion
	// Walk the versions and render only eligible for next article iteration
	for _, version := range article.Versions {
		// Skip the versions that below current article version
		if atVersion >= int(version.VersionID) {
			continue
		}
		sb.WriteString(version.Text)

		// TODO: Show to the user information if his/she's/theirs/nnnn vote already in for one of the sides
		// at this moment this information is hidden
		approveText := fmt.Sprintf("`use the` </br>```gnokey maketx call -pkgpath \"gno.land/r/foundations/gnopedia\" ApproveArticleVersion -args %d -args %d```", article.ID, version.VersionID)
		denyText := fmt.Sprintf("`use the` </br>```gnokey maketx call -pkgpath \"gno.land/r/foundations/gnopedia\" DenyArticleVersion -args %d -args %d```", article.ID, version.VersionID)
		sb.WriteString(fmt.Sprintf("%s\n", col2WithTitle("Vote Approve", approveText, "Vote Deny", denyText)))
	}
	return sb.String()
}

func col2WithTitle(col1Title, col1Text, col2Title, col2Text string) string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("\n\n|**%s**|**%s**|\n", col1Title, col2Title))
	sb.WriteString("|:---|---:|\n")
	sb.WriteString(fmt.Sprintf("| %s | %s |\n", col1Text, col2Text))
	return sb.String()
}

func isPendingVersionAvailable(article *Article) bool {
	// Set the current staged version to zero or current article version
	atVersion := article.CurrentVersion
	// Walk the versions and render only eligible for next article iteration
	for _, version := range article.Versions {
		// Skip the versions that below current article version
		if atVersion >= int(version.VersionID) {
			continue
		}
		return true
	}
	return false
}

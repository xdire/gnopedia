package gnopedia

import (
	fmt "gno.land/p/demo/ufmt"
	"std"
	"time"

	"gno.land/p/demo/uintavl"
)

// id (uint64) -> *Article
var articles = uintavl.NewTree()

type Article struct {
	ID                       uint64
	MinMajority              uint64 // define minimal majority for the article to have the version to replace previous version
	VotingGracePeriod        uint64 // seconds for graceful voting, allows to accumulate version votes without version update
	MinVersionContribCost    int    // the contribution size author need to put on stake to create version of article
	Title                    string
	Versions                 []*ArticleContent // defined as a slice, however depending on storage optimizations can (should) be tree, LL or the Queue type (Recent first)
	CurrentVersion           int
	CurrentVersionInDisprove bool
}

// NewArticle Create new article
// Note: it seems variable names here not important for the gnokey documentation, can be descriptive names
// @param mm Minimal Majority required between Approver and Rejection votes
// @param gp Voting Grace period in seconds, meaning no promotion allowed until this period ends
// @param cc Contribution Cost — the stake of the new Article versions to be posted for review
// @param title Title of the article
// @param text Content of the article version
func NewArticle(minMajority, gracePeriod uint64, contribCost int, title, text string) uint64 {
	author := std.PrevRealm().Addr()

	var reward std.Coins
	if withCoins := std.GetOrigSend(); len(withCoins) != 0 {
		reward = withCoins
	}

	id := uint64(articles.Size())
	a := &Article{
		ID:                    id,
		MinMajority:           minMajority,
		VotingGracePeriod:     gracePeriod,
		MinVersionContribCost: contribCost,
		Title:                 title,
		Versions: []*ArticleContent{
			{
				VersionID: 0,
				Author:    author,
				Approved:  nil,
				Declined:  nil,
				Reward:    reward,
				Text:      text,
				CreatedAt: time.Now().UTC(),
			},
		},
		CurrentVersion: -1, // Until any version is approved by the predefined majority, no text should be provided
	}

	if storErr := articles.Set(id, a); storErr {
		panic("cannot use article ID")
	}

	return id
}

func ProposeArticleVersion(id uint64, title, text string) {
	currentUser := std.PrevRealm().Addr()
	article := getArticle(id)

	var contrib std.Coins
	if withCoins := std.GetOrigSend(); len(withCoins) != 0 {
		contrib = withCoins
	}

	if len(contrib) < article.MinVersionContribCost {
		panic(fmt.Sprintf("minimum contribution stake is at %v", article.MinVersionContribCost))
	}

	article.Versions = append(article.Versions, &ArticleContent{
		VersionID: uint64(len(article.Versions)),
		Author:    currentUser,
		Reward:    contrib,
		Title:     title,
		Text:      text,
		CreatedAt: time.Now().UTC(),
		Approved:  nil,
		Declined:  nil,
	})
}

func UpdateArticleVersion(id, version uint64, title, text string) {
	currentUser := std.PrevRealm().Addr()
	article := getArticle(id)
	ver := getArticleVersion(article, version)

	if ver.Promoted {
		panic("version was already promoted")
	}
	if ver.Author == currentUser {
		panic("only author can update")
	}

	ver.Title = title
	ver.Text = text
}

// ApproveArticleVersion
// Abstract user can approve content version adding some stake to the author reward
func ApproveArticleVersion(id, version uint64) {
	currentUser := std.PrevRealm().Addr()

	article := getArticle(id)
	ver := getArticleVersion(article, version)

	// TODO Enable this line when UI testing is complete for the default test account
	//if ver.Author == currentUser {
	//	panic("author cannot vote for article")
	//}

	excludeVoterFromList(ver.Declined, currentUser)
	excludeVoterFromList(ver.Approved, currentUser)
	ver.Approved = append(ver.Approved, currentUser)

	if withCoins := std.GetOrigSend(); len(withCoins) != 0 {
		ver.Reward.Add(withCoins)
	}

	fmt.Println(ver, currentUser)

	// Check if can promote the version of article to be the valid recent version
	if canPromoteVersion(article, ver) {
		article.CurrentVersion = int(ver.VersionID)
		article.CurrentVersionInDisprove = false
		article.Title = ver.Title
		// Send the accumulated reward on the promotion
		if len(ver.Reward) > 0 {
			// TODO Collect the remaining coins from the previous article version to reward the next one
			// Why: previous version might have voters requesting it to be fixed (declined) and they can increase reward to fix
			banker := std.GetBanker(std.BankerTypeRealmSend)
			// Reward after approval happened
			banker.SendCoins(std.CurrentRealm().Addr(), ver.Author, ver.Reward)
		}
		ver.Promoted = true
		ver.PromotedAt = time.Now().UTC()
	}
}

// DenyArticleVersion
// Abstract user can provide a rejection to the article version increasing the reward for author
// to rewrite the article in a better way
// For the already promoted articles it is possible that they can get to the rejection phase where
// additional information will be shown in the UI in regards that content should be carefully reviewed
func DenyArticleVersion(id, version uint64) {
	currentUser := std.PrevRealm().Addr()

	article := getArticle(id)
	ver := getArticleVersion(article, version)

	// TODO Enable this line when UI testing is complete for the default test account
	//if ver.Author == currentUser {
	//	panic("author cannot vote for article")
	//}

	// Remove user from all the lists and save to proper list
	excludeVoterFromList(ver.Approved, currentUser)
	excludeVoterFromList(ver.Declined, currentUser)
	ver.Declined = append(ver.Declined, currentUser)

	if withCoins := std.GetOrigSend(); len(withCoins) != 0 {
		ver.Reward.Add(withCoins)
	}

	// Check if can notify that the most recent version of the article
	if canDemoteVersion(article, ver) {
		article.CurrentVersionInDisprove = true
	}
}

func getArticle(id uint64) *Article {
	a, ok := articles.Get(id)
	if !ok {
		panic("article does not exist")
	}

	var article *Article
	if article, ok = a.(*Article); !ok {
		panic("stored value has a wrong type")
	}

	return article
}

func canPromoteVersion(article *Article, version *ArticleContent) bool {
	if time.Now().Sub(version.CreatedAt).Milliseconds() > int64(article.VotingGracePeriod) {
		if uint64(len(version.Approved)-len(version.Declined)) > article.MinMajority {
			return true
		}
	}
	return false
}

func canDemoteVersion(article *Article, version *ArticleContent) bool {
	// Check if this article is actual current article at the moment
	if uint64(article.CurrentVersion) == version.VersionID && uint64(len(version.Declined)-len(version.Approved)) > article.MinMajority {
		return true
	}
	return false
}

func getArticleVersion(a *Article, version uint64) *ArticleContent {
	if version >= uint64(len(a.Versions)) {
		panic("version out of range of existing versions")
	}
	return a.Versions[version]
}

// TODO Currently rebuilds the slice, should just use the LL or map
func excludeVoterFromList(list []std.Address, voter std.Address) []std.Address {
	replaced := make([]std.Address, len(list))
	for _, addr := range list {
		if addr != voter {
			replaced = append(replaced, addr)
		}
	}
	return replaced
}

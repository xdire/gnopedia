package gnopedia

import (
	"std"
	"time"
)

type ArticleContent struct {
	VersionID  uint64
	Author     std.Address
	Reward     std.Coins // Total reward that Article content contributor would accumulate on review stage
	Title      string
	Text       string
	Promoted   bool
	CreatedAt  time.Time
	PromotedAt time.Time
	Approved   []std.Address // Can be a LinkedList/Tree type of data for serialization purposes
	Declined   []std.Address // Can be a LinkedList/Tree type of data for serialization purposes
}

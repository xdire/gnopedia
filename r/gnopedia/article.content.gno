package gnopedia

import (
	"std"
	"time"
)

type ArticleContent struct {
	VersionID  uint64
	Author     std.Address
	Reward     std.Coins
	Title      string
	Text       string
	Promoted   bool
	CreatedAt  time.Time
	PromotedAt time.Time
	Approved   []std.Address
	Declined   []std.Address
}

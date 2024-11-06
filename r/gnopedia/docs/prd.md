# PRD - Gnopedia 
A simple representation of Wikipedia using GNODEV environment

# Purpose and Scope
Scope of this project is to demonstrate the ease of development
for a content-service like Wikipedia using the Blockchain functions
to allow following:
- add content
- allow users to update content
- make content quality depend on the majority of user-base

# What not in the scope
As humans are creatures with sometimes unpredictable behavior
this project will not try to solve unfair practices or other
similar type of behavior for the content.

# Overview
### GNO Smart Contract
Following the concepts from the GNO workshops smart contract defined
as the storage abstraction with the article elements inside
```
  ┌─Smart Contract────────────┐
  │                           │
  │ ┌─Storage Abstraction───┐ │
  │ │                       │ │
  │ │  ┌─Articles─────────┐ │ │
  │ │  │                  │ │ │
  │ │  │  ┌─Version3────┐ │ │ │
  │ │  │  │             │ │ │ │
  │ │  │  ├─Version2────┤ │ │ │
  │ │  │  │             │ │ │ │
  │ │  │  ├─Version1────┤ │ │ │
  │ │  │  │             │ │ │ │
  │ │  │  └─────────────┘ │ │ │
  │ │  └──────────────────┘ │ │
  │ └───────────────────────┘ │
  └───────────────────────────┘


```

### General flow
Primary function of the smart contract is to provide user function to publish
the article or add version of content to some article.

Then version of the content can be voted to be approved or declined by the community
of users, or particular addresses (out of scope of this document).

As users vote — they can increase the reward for the article or just vote down
the effort.

If majority approves (defined per contract what majority is) through the grace
period, then version gets as the published content for the article.
```


            ┌──────────────────┐
     ┌─────▶│      User 1      │                                            ┌────────────────┐
     │      └─────────┬────────┘                                     Votes──│     User 2     │
     │                │                                               │     └────────────────┘
     │            Creates                                             │
     │                │                                               │
     │      ┌─────────▼────────┐                                      │
     │   ┌──│     Article      │                                      │
     │   │  └─────────┬────────┘         Λ                            │
     │   │            │                 ╱ ╲                           │
     │   │          With               ╱   ╲       ┌────────────┐     │
     │   │            │               ╱     ╲──────│ ApprovedBy │◀────┘
     │   │  ┌─────────▼────────┐     ╱  Has  ╲     └────────────┘
     │   │  │ Content Version 0├────▕ Majority▏
     │   │  └──────────────────┘     ╲       ╱     ┌────────────┐
     │   │                            ╲     ╱──────│ DeclinedBy │◀────┐     ┌────────────────┐
     │   │                             ╲   ╱       └────────────┘    Votes──│     User 3     │
     │   │                              ╲ ╱                                 └────────────────┘
     │   │  ┌──────────────────┐         V
     │   └──│ Current Content  │         │
     │      └──────────────────┘         │
     │                ▲                  │
   Send               │                  ▼
  Rewards       Set pointer to       ┌───────┐
 Added by          the voted         │  Yes  │
 Approvers      content update       └───────┘
     │                │                  │
     │                │                  │
┌────────┐  ┌──────────────────┐         │
│ Reward │  │ Content Version X│         │
└────────┘  └──────────────────┘         │
     ▲                ▲                  │
     │                │                  │
     └────────────────┴──────────────────┘

```
# Use Cases

### The voting for the existing content
When quality of the material is subpar (or similar expression) voters can affect the visibility of the content
in following way:

- The article will display a notification that this version of content
is not validated by the community (downvotes after publish)


- This should encourage the authors to provide next version of the article
to be added by the contributor seeking the reward of helping the community

```shell


                                                                                       ┌────────────────┐
                                                                                Votes──│     User 2     │
                                                                                 │     └────────────────┘
                                                                                 │
                                                 Λ                               │
                                                ╱ ╲                              │
           ┌────────────────────┐              ╱   ╲                             │
       ┌──▶│      Article       │             ╱     ╲                            │
       │   └──────────┬─────────┘            ╱       ╲                           │
       │              │                     ╱         ╲       ┌────────────┐     │
       │              │                    ╱   Has     ╲──────│ ApprovedBy │     │
       │   ┌──────────┴──────────┐        ╱  Majority   ╲     └────────────┘     │
       │   │Content With Room For│       ▕  and content  ▏                       │
       │   │     Improvement     │        ╲ is published╱     ┌────────────┐     │
       │   └─────────────────────┘         ╲           ╱──────│ DeclinedBy │◀────┤     ┌────────────────┐
       │                                    ╲         ╱       └────────────┘    Votes──│     User 3     │
       │                                     ╲       ╱                                 └────────────────┘
       │                                      ╲     ╱
       │                                       ╲   ╱
       │                                        ╲ ╱
       │                                         V
       │                                         │
       │                                         │
       │                                         │
       │  ┌─────────────────────┐                │
       │  │  Mark Content As    │                ▼
       │  │  Questionable and   │           ┌─────────┐
       └──│  add to rewards to  │◀──────────│   Yes   │
          │  make the next      │           └─────────┘
          │  version of article │
          └─────────────────────┘
```

# Assumptions
Only limited section of GNO Platform was studied to create this concept, following assumptions
will be used for this particular design:
- Smart contract storage using AVL Tree provided by demo package
- Articles stored within the storage abstraction and target GNODEV environment
- Some part of the application code can mention TODO statements as the pieces of the
implementation that can or should be created to make better functional
- No test-coverage assumed for this feature
- Shell GNOKEY commands as RPC triggers

# High level plan
Following steps will define the definition of task completion
- Design Approval Process (as PR review)
- Minimal solution for the goals described above

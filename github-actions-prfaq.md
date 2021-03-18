# PRFAQ for Github Actions as D2L's standard build tool

Note: this document uses the [PRFAQ style](../documentation-styles/prfaq).

## Internal Press Release (PR)

### D2L now uses one consistent build tool.

#### All D2L CI builds now use Github Actions

Summary:
TED announced today that all software builds are using Github Actions.
Builds are executed on D2L-managed EC2 instances, providing optimal compute cost.
Developers can move between codebases without having to learn a new build system.

Problem:
We had a proliferation of build tools: Jenkins, CircleCI, TravisCI, AppVeyor, CodeBuild, CodePipeline.
We had isolated pockets of expertise, making it hard to move between projects.
We had redundant spending that could be better used elsewhere.
We had no standard way to observe build health.

Solution:
We moved all our builds to Github Actions.
All teams and products use the same build system, making it easy to move between them.
We no longer pay multiple vendors, and get Github Actions as part of our existing Github spend.
We can observe a repos' build directly in the repo UI or automate using a single API.

Stakeholder Quote(s):
(forthcoming)

## Stakeholder FAQs

### Why not consolidate on one of our existing tools?  (Obligatory [xkcd reference](https://xkcd.com/927/))

Github Actions is more compelling than any of the existing tools for a few reasons:

1. Fewer vendors overall. Actions is built in to Github, and we're going to be storing sourcecode on Github for a long time.  If we consolidate on, say, TravisCI, we'll still have both Github and TravisCI as vendors.  If we consolidate on Github Actions, we'll have one fewer vendors.
1. Status checks built right in to the PR UI.
1. Easy integration with GitHub APIs.  Every workflow can get a temporary API token to interact with GitHub's API (e.g. post comments, submit new PRs, ...)
1. Flexibility.  Github Actions allow us to run our own agents, which gives us a lot of ability to control costs.  SaaS companies always need to sell their service at a markup above compute cost.  They'll never be able to run our builds at a cost less than we can run them on AWS.
1. More generic.  Most CI providers are focused on a narrow set of workflows (building in response to commits).  GitHub Actions supports [a wide variety of events](https://docs.github.com/en/actions/reference/events-that-trigger-workflows) such as scheduled workflows, workflows that run in response to comments, etc.

## Implementation FAQs

### This is a HUGE lift.  Can we really get there?

Yes, it is a huge lift, and yes we can get there.

The first step will be to get new builds running in Github Actions.
This has already started as some teams have picked up Github Actions already.

Then we'll move on to migrating some existing builds from AppVeyor, TravisCS, or CircleCI to Github Actions.
We'll start with the simplest ones to move and move on to harder ones.
We will aim to retire entire services if possible.
E.g. we have fewer builds in AppVeyor, and they are mostly C# Libraries; so AppVeyor is likely to be easiest to replace at the start.

Eventually we'll move to migrating the LMS build to Github Actions.
This could start by having Github actions trigger Jenkins tasks (we may have already done this).
Then we can look to move individual steps to Github Actions one-by-one.

### Does Github Actions do everything we need in our builds?

Not yet.
GitHub Actions doesn't support manual approval steps, but [adding manual approval steps is on GitHub's roadmap](https://github.com/github/roadmap/issues/99).
Terraform deployments commonly have a manual approve step.

### What workflows need to be figured out but haven't?

1. Package Management.  A lot of our AppVeyor builds produce NuGet packages which we use through AppVeyor's built-in package functionality.  We need a standard pattern for this in Github Actions.

### Why not consolidate on TravisCI?

Travis CI was recently bought by Idera and then "stripped for parts": https://www.reddit.com/r/programming/comments/atjltu/layoffs_at_travis_ci_their_team_was_being/.

This has significantly damaged our trust in TravisCI.

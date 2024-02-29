# SiestaExt

SwiftUI and Combine additions to [Siesta – the elegant way to
write iOS / macOS REST clients](https://github.com/bustoutsolutions/Siesta).
(If you don't know Siesta, you should check it out. It's great.)

Because of when it was written, Siesta is callback-based. Now we have
Combine publishers, `@ObservableObject`... oh yes, and SwiftUI.

## Features

- Easily use Siesta with SwiftUI
- Combine publishers for resources and requests
- A typed wrapper for Resource (😱 controversial!) for clearer APIs


## Project status

🔴 Not quite ready yet 🔴  The code should be pretty stable, but 
- tests need some attention
- more docs in general
- other non-code stuff



## Examples

Read on, or jump straight into the GithubBrowser example app – it's the
original Siesta example app rewritten in SwiftUI, and it's a thing of beauty :-)

### First off, understand `TypedResource`

Unlike Siesta's `Resource`, most things in this project are strongly typed.
Your starting point is `TypedResource<T>`, which you get by calling `typed()
` on a `Resource`. For example `GithubAPI`'s methods now return
`TypedResources`:

```swift
func repository(ownedBy login: String, named name: String) -> TypedResource<Repository> {
    service
    .resource("/repos")
    .child(login)
    .child(name)
    .typed()
}
```

Notice that the rest of your app now knows what data type will be loaded by
your API methods!

`TypedResource` is just a wrapper, so you can refer
to `someTypedResource.resource` to get
the underlying `Resource` when you need to.

Yes, using a typed wrapper like this is certainly an opinionated choice, but
it makes a lot of things in here work better. Plus your API classes are now
more expressive. If you really don't like this, you can still base 
everything around `Resource`, and call `typed()` when you need to.


### Using a Resource in SwiftUI

**Just look at the brevity of this code!** You need nothing more than this
and the API class. I hope you're not getting paid by the line.

```swift
struct SimpleSampleView: View {
    let repoName: String
    let owner: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(owner)/\(repoName)")
            .font(.title)

            // Here's the good bit:
            ResourceView(GitHubAPI.repository(ownedBy: owner, named: repoName)) { (repo: Repository) in
                // This isn't rendered until content is loaded
                if let starCount = repo.starCount {
                    Text("★ \(starCount)")
                }
                if let desc = repo.description {
                    Text(desc)
                }
            }

            Spacer()
        }
        .padding()
    }
}
```

Or, make your data parameter optional, and render something when you don't
have data yet (but read on for a fancier solution):

```swift
ResourceView(GitHubAPI.repository(ownedBy: owner, named:
repoName)) { (repo: Repository?) in
    if let repo {
        if let starCount = repo.starCount {
            Text("★ \(starCount)")
        }
        if let desc = repo.description {
            Text(desc)
        }
    }
    else {
        Text("Waiting patiently for the internet...")
    }
}
```

### Get a spinner, error reporting and a retry button with (almost) no effort

By making a tiny change you can have all of these things:

```swift
struct StatusSampleView: View {
    let repoName: String
    let owner: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(owner)/\(repoName)")
            .font(.title)

            ResourceView(GitHubAPI.repository(ownedBy: owner, named:
            repoName), /* Added this bit: */ statusDisplay: .standard) { (repo:
                Repository) in
                if let starCount = repo.starCount {
                    Text("★ \(starCount)")
                }
                if let desc = repo.description {
                    Text(desc)
                }
            }

            Spacer()
        }
        .padding()
    }
}

```

This is inspired by Siesta's `ResourceStatusOverlay`, and you can control
the relative priorities of loading, error and data states in much the same
way: with the array of rules you pass. For
example, to
display data, no matter how stale: `statusDisplay: [.anyData, .loading,
.error]`.


### ...but you possibly want to render those yourself, more nicely

This is easy – just write your own version of `ResourceView`. That sounds
onerous, but in fact you have very little code to write – most of the
mechanics is farmed out to a protocol and a helper class. Just have a look at
the main implementation of `ResourceView`.


### Multiple resources

Your content block can use more than one resource.

(Alternatively you could
use separate `ResourceView`s of course, but your content might be
intertwined, or you might want everything loaded before anything is displayed.)

You can also nest `ResourceView`s. Slice and dice things however you want.

```swift
struct MultipleSampleView: View {
    let repoName: String
    let owner: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(owner)/\(repoName)")
            .font(.title)

            ResourceView(
                GitHubAPI.repository(ownedBy: owner, named: repoName),
                GitHubAPI.activeRepositories
            ) { (repo: Repository, active: [Repository]) in
                if let starCount = repo.starCount {
                    Text("★ \(starCount)")
                }
                if let desc = repo.description {
                    Text(desc)
                }

                Text("In unrelated news, the first active repository is called \(active.first!.name).")
            }

            Spacer()
        }
        .padding()
    }
}
```

### Want more control, less magic?

If you want to do something more complex, or create your own building blocks,
or if you're an MVVM hound and the
examples above are giving you conniptions with their lack of model objects,
you can step down a level:

#### Combine publishers

`TypedResource` (and `Resource` for that matter) have publishers that output
progress:

- `statePublisher()` - outputs `ResourceState<T>`: a snapshot of
  a resource's state at a point in time. It contains all the usual fields
  you'll be interested in (`latestError`, etc), plus typed content.
- `contentPublisher()` outputs content when there is some; it's convenient
  if you don't care about the rest of the state
- `optionalContentPublisher()` is the same but outputs `nil` to let you know
  there's no content yet

Subscribing to a publisher triggers `loadIfNeeded()`, and retains
the `Resource` until you unsubscribe.


#### ObservableResource

Calling `someTypedResource.observable()` gives you `ObservableResource`, an
`ObservableObject` that publishes resource state.

This makes a good `@ObservedObject` in your views, for example.


#### Publishers for requests too

If you like Combine, `Resource` has request publisher methods, and there are
publishers available directly on `Request` too.


### How about UIKit?

You could use this project's publishers along with CombineCocoa. There are 
examples of that in 
[this archived Siesta fork](https://github.com/luxmentis/Siesta).

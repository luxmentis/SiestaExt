# SiestaExt

SwiftUI and Combine additions to [Siesta – the elegant way to
write iOS / macOS REST clients](https://github.com/bustoutsolutions/Siesta).

Because of when it was written, Siesta is callback-based. Now we have
Combine publishers, `@ObservableObject`, and oh yes – SwiftUI.

*(If you don't know Siesta, have a quick look at a couple of the examples below –
and be amazed by the simplicity of SwiftUI code accessing a REST API. Then
go and read up on Siesta.)*


## Features

- Easily use Siesta with SwiftUI
- Combine publishers for resources and requests
- A typed wrapper for Resource (😱 controversial!) for clearer APIs


## Examples

Read on, or jump straight into one of the apps in the `Examples` folder:
- SiestaExtSimpleExample: a good starting point that shows you the basics
- GithubBrowser: it's the original Siesta example app rewritten in SwiftUI. 
  Be amazed at how little code there is – it's a thing of beauty :-)


## Tutorial

### First off, understand `TypedResource`

Unlike Siesta's `Resource`, most things in this project are strongly typed.
Your starting point is `TypedResource<T>`, where T is the content type.

If you define your API methods using `TypedResource`, the rest of your app knows what types it's
getting! For example, from the `GithubAPI` example app:

```swift
func repository(ownedBy login: String, named name: String) -> TypedResource<Repository> {
    service
    .resource("/repos")
    .child(login)
    .child(name)
    .typed() // Create a TypedResource from a Resource. Type inference usually figures out <T>.
}
```

`TypedResource` is just a wrapper, so you can refer
to `someTypedResource.resource` when you need to.

(Yes, using a typed wrapper like this is certainly an opinionated choice, but
it makes a lot of things in here work better. Plus your API classes are now
more expressive. If you really don't like this, you can still base 
everything around `Resource`, and call `typed()` when you need to.)


### Use a Resource in SwiftUI

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

Or, by making your data parameter optional you can render something when you don't
have data yet (but read on for a fancier solution):

```swift
ResourceView(GitHubAPI.repository(ownedBy: owner, named: repoName)) { (repo: Repository?) in
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

            ResourceView(GitHubAPI.repository(ownedBy: owner, named: repoName), /* Added this bit: */ displayRules: .standard) { (repo:
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
display data, no matter how stale: `displayRules: [.anyData, .loading,
.error]`.

There are a few predefined sets like `.standard` (used above), which is short for
to `[.anyData, .loading, .error]`


### But possibly you want to render progress and errors yourself

This is easy – just write your own version of `ResourceView`. That sounds
onerous, but in fact you have very little code to write – most of the
mechanics is farmed out to a protocol and a helper class. Just have a look at
the main implementation of `ResourceView`.


### Multiple resources, either all at once...

Your content block can use more than one resource, and will be displayed once they
all have content. Particularly useful if you're intertwining content from multiple
resources.

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

### ...or you can nest resource views

In this example, the post is displayed first, then the comments are loaded. You could
load them both at once, but this way your user can get reading sooner.

Also, notice the loading of user details; this _must_ be nested as it requires the userId
from the post.
```swift
ResourceView(api.post(id: postId), displayRules: .standard) { (post: Post) in
    VStack {
        VStack(alignment: .leading, spacing: 20) {
            Text(post.title).font(.title)
            Text(post.body).font(.body)
            
            ResourceView(api.user(id: post.userId)) {
                Text("– \(user.name) (\(user.email))").font(.footnote)
            }
        }
        .padding()

        ResourceView(api.comments(postId: post.id), displayRules: .standard) {
            List($0) { comment in
                VStack(alignment: .leading) {
                    Text(comment.body)
                    Text("– \(comment.name) (\(comment.email))").font(.footnote)
                }
            }
        }

        Spacer()
    }
}
```


### Fakes for Previews

Chances are you don't want to make real network requests in your SwiftUI previews. `TypedResource` has built-in
support for fakes, so you can do things like this:

```swift
struct UserView: View {
    let userId: Int
    let fakeUser: TypedResource<User>?
  
    ...
  
    var body: some View {
        ResourceView(fakeUser ?? api.user(id: userId)) {
            ...
        }
    }
}

// With fake data
#Preview {
    UserView(fakeUser: User(id: 1, name: "Persephone", email: "p@there.com"))
}

// See what the loading view looks like
#Preview("Loading") {
    UserView(fakeUser: .fakeLoading())
}

// See what the error view looks like
#Preview("Failed") {
    UserView(fakeUser: .fakeFailure(RequestError(...)))
}
```


### Load things that aren't Siesta resources!

Parts of your app might load data from places other than Siesta. It would be a 
shame to lose `ResourceView` and its display logic just because your data comes from a different source.
`Loadable` to the rescue – it's an abstraction of the basics of Siesta's resource
loading paradigm, and `ResourceView` will load anything `Loadable` (`TypedResource` is a `Loadable`).

If you have a `Publisher` you can use that – `Loadable` conformance is built in – otherwise implement `Loadable` yourself.

```swift
ResourceView(someLongRunningCalculationPublisher.loadable(), displayRules: .standard) { (answer: Int) in
    Text("And the answer is: \(answer)")  // you just know it'll be 42
}
```



### Want more control, less magic?

If you want to do something more complex, or create your own building blocks,
or if you're an MVVM hound and the
examples above are giving you conniptions with their lack of model objects,
you can step down a level:

#### Published properties

`TypedResource` is an `ObservableObject`, and its `state` and `content`variables are 
`@Published`.

`TypedResource.state` is a `ResourceState<T>` – a snapshot of the resource's state at a point in time.
It contains all the usual fields you'll be interested in (`latestError`, etc), plus 
typed content.


#### Combine publishers

`TypedResource` (and any `Loadable` for that matter) have publishers that output
progress:

- `statePublisher()` outputs `ResourceState<T>`
- `contentPublisher()` outputs content when there is some; it's convenient
  if you don't care about the rest of the state
- `optionalContentPublisher()` is the same but outputs `nil` to let you know
  there's no content yet

Subscribing to a publisher triggers `loadIfNeeded()`, and retains
the `Resource` until you unsubscribe.


#### Publishers for requests too

If you like Combine, `Resource` has request publisher methods, and there are
publishers available directly on `Request` too.


### How about UIKit?

You could use this project's publishers along with CombineCocoa. There are 
examples of that in 
[this archived Siesta fork](https://github.com/luxmentis/Siesta).

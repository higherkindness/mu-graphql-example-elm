# mu-graphql-example-elm 🌳

![Elm CI]

![preview]

To run this example, you need to run the [Mu-Haskell] GraphQL server example (with [Stack]):

```sh
$ stack run library-graphql
```

And, in another terminal, this project:

```sh
# Fetch schema and save it to file
$ curl https://raw.githubusercontent.com/higherkindness/mu-haskell/master/examples/library/library.graphql > library.graphql
$ npm run codegen
$ npm start
```

## Features

- [x] Queries (Search authors by name and books by title)
- [ ] Mutations (add an author)
- [ ] Subscriptions (observe just added authors)

## Notes

- [elm-graphql] supports code-generation from introspection files, local schema definition files and remote servers with introspection enabled _(it usually is)_.
- [elm-graphql] provides queries as `Task`s, which makes them much composable, than `Cmd`s.
- both [elm-graphql] and [elm-app] can be installed as global dependencies, but we don't consider it a good practice, because it immediately becomes harder to maintain versions.
- old generated files are removed by [elm-graphql] automatically, we don't need to worry about it.
- `curl` is not supported on windows systems, but we need to use it here as long as actual schema is stored in another repo (and that is good, otherwise schema definition file will be decoupled from the actual implementation and some day will become invalid). However, in real applications it could be great to have both server and client code located in one repo together with schema.
- search does not work as expected, but that's not a client's fault. Here is how example server behaves:

    - Request

    ```sh
    curl \
      -X POST \
      -H "Content-Type: application/json" \
      -d '{
        "query": "{
          books(title: \"Recursion ans Laziness\") {
            title
            id
            author {
              name
            }
          }
        }"
      }' \
      http://localhost:8000
    ```

    - Response

    ```json
    {
      "data": {
        "books": [
          {
            "author": {
              "name": "Robert Louis Stevenson"
            },
            "id": 1,
            "title": "Treasure Island"
          },
          {
            "author": {
              "name": "Robert Louis Stevenson"
            },
            "id": 2,
            "title": "Strange Case of Dr Jekyll and Mr Hyde"
          },
          {
            "author": {
              "name": "Immanuel Kant"
            },
            "id": 3,
            "title": "Critique of Pure Reason"
          },
          {
            "author": {
              "name": "Michael Ende"
            },
            "id": 4,
            "title": "The Neverending Story"
          },
          {
            "author": {
              "name": "Michael Ende"
            },
            "id": 5,
            "title": "Momo"
          }
        ]
      }
    }

    ```

  [elm ci]: https://github.com/kutyel/mu-graphql-example-elm/workflows/Elm%20CI/badge.svg
  [preview]: docs/preview.png
  [mu-haskell]: https://github.com/higherkindness/mu-haskell
  [stack]: https://docs.haskellstack.org/en/stable/README/#how-to-install
  [elm-graphql]: https://github.com/dillonkearns/elm-graphql/
  [elm-app]: https://github.com/halfzebra/create-elm-app

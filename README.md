# mu-graphql-example-elm 🌳

![Elm CI]

![preview]

To run this example, you need to run the [Mu-Haskell] GraphQL server example (with [Stack]):

```sh
$ stack run library
```

And, in another terminal, this project:

```sh
# Fetch schema and save it to file
$ npm install
$ curl https://raw.githubusercontent.com/higherkindness/mu-haskell/master/examples/library/library.graphql > library.graphql
$ npm run codegen
$ npm start
```

## Features

- [x] Queries (Search authors by name and books by title, combine queries into one)
- [x] Mutations (add an author)
- [ ] Subscriptions (observe just added authors)

## Notes

- [elm-graphql] also supports code-generation from introspection files, local schema  files and remote servers with introspection enabled _(it usually is)_.
- In this particular example it's better for us to use exactly that schema  file which was used for implementing backend, rather than keeping a duplicate schema in the client repo (in this case they will become inconsistent some day). However, in real applications it could be great to have both backend and client code located in one repo together with the schema.
- [elm-graphql] provides queries as `Task`s, which makes them much composable than `Cmd`s.
- both [elm-graphql] and [elm-app] can be installed as global dependencies, but we don't consider it a good practice, because it immediately becomes harder to maintain versions.
- old generated files are removed by [elm-graphql] automatically, we don't need to worry about it.
- `curl` is not supported on Windows systems, but you can download the schema file manually.


  [elm ci]: https://github.com/kutyel/mu-graphql-example-elm/workflows/Elm%20CI/badge.svg
  [preview]: docs/preview.png
  [mu-haskell]: https://github.com/higherkindness/mu-haskell
  [stack]: https://docs.haskellstack.org/en/stable/README/#how-to-install
  [elm-graphql]: https://github.com/dillonkearns/elm-graphql/
  [elm-app]: https://github.com/halfzebra/create-elm-app

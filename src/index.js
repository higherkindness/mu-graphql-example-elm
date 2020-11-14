import "./main.css";
import { Elm } from "./Main.elm";

document.addEventListener("DOMContentLoaded", () => {
  const app = Elm.Main.init({ node: document.getElementById("root") });

  let wsConnection;

  const graphqlWebsocketsUrl = "ws://localhost:8000";

  app.ports.subscribeToAllBooks.subscribe((subscriptionString) => {
    console.log(subscriptionString); // TODO: remove log
    if (!wsConnection) {
      console.log("Trying to open websocket connection...");
      wsConnection = new WebSocket(graphqlWebsocketsUrl, "graphql-ws");

      const onOpen = () => {
        console.log("Websocket connection is now open");
        const wsInitMessage = { type: "connection_init", payload: {} };

        // TODO: This temporary query will be removed once library server is fixed
        const tempQueryString = `subscription {
          allBooks {
            title
            imageUrl
          }
        }`;

        const wsSubscriptionMessage = {
          id: "1",
          type: "start",
          payload: {
            variables: {},
            query: tempQueryString, // subscriptionString,
          },
        };

        wsConnection.send(JSON.stringify(wsInitMessage));
        wsConnection.send(JSON.stringify(wsSubscriptionMessage));
      };

      const onMessage = (event) => {
        // event.data is a JSON string.
        // It's safer to decode JSON in Elm, but requires ingoring irrelevant messages in Elm.
        // We choose safety here, but we also can filter (which means decode) messages in JS-side
        app.ports.gotSubscriptionData.send(event.data);
      };

      wsConnection.addEventListener("open", onOpen);
      wsConnection.addEventListener("message", onMessage);
    }
  });
});

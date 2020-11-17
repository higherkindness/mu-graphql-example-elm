import "./main.css";
import { Elm } from "./Main.elm";

document.addEventListener("DOMContentLoaded", () => {
  const app = Elm.Main.init({ node: document.getElementById("root") });

  let isActive = false;

  const graphqlWebsocketsUrl = "ws://localhost:8000";

  app.ports.subscribeToAllBooks.subscribe((subscriptionString) => {
    if (!isActive) {
      isActive = true;
      console.log("Attempting to open websocket...");

      const socket = new WebSocket(graphqlWebsocketsUrl, "graphql-ws");

      const onUnsubscribe = () => {
        console.log("Attempting to close websocket...");
        socket.close();
      };

      socket.onclose = (closeEvent) => {
        isActive = false;
        app.ports.unsubscribe.unsubscribe(onUnsubscribe);
        console.log("Websocket closed.");
      };

      app.ports.unsubscribe.subscribe(onUnsubscribe);

      socket.onerror = (error) => console.log("Websocket error", error);

      socket.onopen = (event) => {
        console.log("Websocket is now open");
        const initMessage = { type: "connection_init", payload: {} };
        const subscriptionMessage = {
          id: "1",
          type: "start",
          payload: {
            variables: {},
            query: subscriptionString,
          },
        };
        event.target.send(JSON.stringify(initMessage));
        event.target.send(JSON.stringify(subscriptionMessage));
      };

      socket.onmessage = (event) => {
        // event.data is a JSON string.
        // It's safer to decode JSON in Elm, but requires ingoring irrelevant messages in Elm.
        // We choose safety here, but we also can filter (which means decode) messages in JS-side
        app.ports.subscriptionDataReceiver.send(event.data);
      };
    }
  });
});
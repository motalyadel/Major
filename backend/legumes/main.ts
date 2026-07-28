import { Elysia } from "elysia";

const app = new Elysia().get("/", () => ({ hello: "Motaly👋" })).listen(8080);

console.log(`Listening on ${app.server!.url}`);

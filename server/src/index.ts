import { Hono } from "hono";
import { cors } from "hono/cors";
import { serveStatic } from "hono/bun";
import type { ApiResponse } from "shared/dist";

export const app = new Hono()

.use(cors())

.get("/api", (c) => {
	return c.text("Hello Hono!");
})

.get("/api/hello", async (c) => {
	const data: ApiResponse = {
		message: "Hello BHVR!",
		success: true,
	};

	return c.json(data, { status: 200 });
});

// Use absolute path for static files
const staticRoot = process.env.NODE_ENV === "production" ? "/app/server/static" : "./static";

app.use("*", serveStatic({ root: staticRoot }));
 
app.get("*", async (c, next) => {
  return serveStatic({ root: staticRoot, path: "index.html" })(c, next);
});

const port = parseInt(process.env.PORT || "3000");


export default {
	port,
	fetch: app.fetch,
  };

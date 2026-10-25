import { createTRPCReact } from "@trpc/react-query";
import type { AppRouter } from "@workspace/api-core";

export const api = createTRPCReact<AppRouter>();

import { drizzle, type MySql2Database } from "drizzle-orm/mysql2";
import mysql from "mysql2/promise";
import * as schema from "./schema";

export type DentalDatabase = MySql2Database<typeof schema>;

let database: DentalDatabase | null = null;
let pool: mysql.Pool | null = null;

export function isDatabaseConfigured(): boolean {
  return Boolean(process.env.TIDB_URL);
}

export function getDatabase(): DentalDatabase | null {
  const connectionString = process.env.TIDB_URL;
  if (!connectionString) return null;
  if (database) return database;

  const parsed = new URL(connectionString);
  if (parsed.protocol !== "mysql:") {
    throw new Error("TIDB_URL must use the mysql:// scheme.");
  }

  pool = mysql.createPool({
    host: parsed.hostname,
    port: Number(parsed.port || "4000"),
    user: decodeURIComponent(parsed.username),
    password: decodeURIComponent(parsed.password),
    database: decodeURIComponent(parsed.pathname.replace(/^\/+/, "")),
    ssl: { minVersion: "TLSv1.2", rejectUnauthorized: true },
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    enableKeepAlive: true,
  });
  database = drizzle(pool, { schema, mode: "default" });
  return database;
}

export async function closeDatabase(): Promise<void> {
  if (pool) await pool.end();
  pool = null;
  database = null;
}

export * from "./schema";

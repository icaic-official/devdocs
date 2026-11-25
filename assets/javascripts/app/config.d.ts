/**
 * The build-time configuration, rendered by app/config.js.erb.
 *
 * The module is generated, so its shape is declared here rather than in JSDoc.
 */
export interface AppConfig {
  /** The path the app is served under, without a trailing slash; empty at the root. */
  base_path: string;
  db_filename: string;
  /** Slugs enabled for a first-time visitor. */
  default_docs: string[];
  /** Alternative spellings, by the name they resolve to. */
  docs_aliases: Record<string, string>;
  /** Where the documentation files are served from. */
  docs_origin: string;
  env: string;
  history_cache_size: number;
  index_filename: string;
  max_results: number;
  /**
   * Whether the server has each doc's db.json, the file a doc is installed
   * for offline use from. Static hosts with a size cap leave them out.
   */
  offline_data: boolean;
  production_host: string;
  /** Served from a domain other than production_host on purpose. */
  self_hosted: boolean;
  /** The query parameter a search is read from. */
  search_param: string;
  sentry_dsn: string;
  /** Cache-busting stamp for the offline data. */
  version: number;
  release: string;
  mathml_stylesheet: string;
  favicon_spritesheet: string;
  service_worker_path: string;
  service_worker_enabled: boolean;
}

export const config: AppConfig;

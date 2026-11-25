// @ts-check

import { config } from "../app/config.js";

/*
 * The app can be served under a path (e.g. `/devdocs` on a GitHub Pages
 * project site) rather than at the root of its domain.
 *
 * Internally every path is relative to that base: the router's routes, the
 * paths in history state and `Doc#fullPath()` all start at `/`. The base is
 * added wherever a path leaves the app (an `href`, the address bar, a
 * `location` assignment) and removed wherever one comes in.
 */

/**
 * @param {string} path An app path, starting with `/`.
 * @returns {string} The URL path the browser sees.
 */
export const withBase = (path) =>
  config.base_path && path.startsWith("/") ? config.base_path + path : path;

/**
 * @param {string} path A URL path, as in `location.pathname`.
 * @returns {string | null} The app path, or null when the URL is outside the app.
 */
export const withoutBase = (path) => {
  const base = config.base_path;
  if (!base) return path;
  if (path === base) return "/";
  return path.startsWith(`${base}/`) ? path.slice(base.length) : null;
};

/** @returns {string} The app path of the current page. */
export const currentAppPath = () => withoutBase(location.pathname) ?? "/";

// @ts-check

import assert from "node:assert/strict";
import test from "node:test";

import { config } from "../../assets/javascripts/app/config.js";
import { withBase, withoutBase } from "../../assets/javascripts/lib/base_path.js";

/**
 * @param {string} base
 * @param {() => void} fn
 */
const withBasePath = (base, fn) => {
  const previous = config.base_path;
  config.base_path = base;
  try {
    fn();
  } finally {
    config.base_path = previous;
  }
};

test("at the root of a domain, paths pass through unchanged", () => {
  withBasePath("", () => {
    assert.equal(withBase("/python~3.13/library/os"), "/python~3.13/library/os");
    assert.equal(withoutBase("/settings"), "/settings");
  });
});

test("under a base path, app paths gain it and URL paths lose it", () => {
  withBasePath("/devdocs", () => {
    assert.equal(withBase("/"), "/devdocs/");
    assert.equal(withBase("/#q=numpy"), "/devdocs/#q=numpy");
    assert.equal(withoutBase("/devdocs/python~3.13/"), "/python~3.13/");
    assert.equal(withoutBase("/devdocs"), "/");
  });
});

// A link to a sibling site on the same host (another GitHub Pages project of
// the same owner) must be left to the browser rather than routed in-app.
test("under a base path, URLs outside it aren't the app's", () => {
  withBasePath("/devdocs", () => {
    assert.equal(withoutBase("/docs/technical-appendix.html"), null);
    assert.equal(withoutBase("/devdocsx/"), null);
  });
});

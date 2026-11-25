// @ts-check

import { $ } from "../lib/util.js";
import { withBase } from "../lib/base_path.js";
/** @import { Doc } from "../models/doc.js" */
/** @import { Entry } from "../models/entry.js" */
/** @import { Type } from "../models/type.js" */

/**
 * The breadcrumb above the content: the doc, then the type, then the entry.
 *
 * @param {Doc} doc
 * @param {Type} [type]
 * @param {Entry} [entry]
 * @returns {string}
 */
export const path = function (doc, type, entry) {
  const arrow = '<svg class="_path-arrow"><use xlink:href="#icon-dir"/></svg>';
  let html = `<a href="${withBase(doc.fullPath())}" class="_path-item _icon-${
    doc.icon
  }">${doc.fullName}</a>`;
  if (type) {
    html += `${arrow}<a href="${withBase(type.fullPath())}" class="_path-item">${
      type.name
    }</a>`;
  }
  if (entry) {
    html += `${arrow}<span class="_path-item">${$.escape(entry.name)}</span>`;
  }
  return html;
};

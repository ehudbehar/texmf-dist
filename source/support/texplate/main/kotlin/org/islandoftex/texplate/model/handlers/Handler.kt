// SPDX-License-Identifier: BSD-3-Clause
package org.islandoftex.texplate.model.handlers

/**
 * Interface for handlers.
 *
 * @version 1.0
 * @since 1.0
 */
interface Handler {
    /**
     * Apply the handler in the string.
     *
     * @param string The string.
     * @return The resulting object.
     */
    fun apply(string: String?): Any?
}

// SPDX-License-Identifier: BSD-3-Clause
package org.islandoftex.texplate.model.handlers

/**
 * Implements a boolean handler.
 *
 * @version 1.0
 * @since 1.0
 */
class BooleanHandler : Handler {
    /**
     * Applies the conversion to the string.
     *
     * @param string The string.
     * @return A list.
     */
    override fun apply(string: String?): Any? {
        return listOf("true", "1", "yes").contains(string!!.lowercase())
    }
}

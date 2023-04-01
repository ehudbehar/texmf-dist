// SPDX-License-Identifier: BSD-3-Clause
package org.islandoftex.texplate.model.handlers

/**
 * Implements a CSV list handler.
 *
 * @version 1.0
 * @since 1.0
 */
class CSVListHandler : Handler {
    /**
     * Applies the conversion to the string.
     *
     * @param string The string.
     * @return A list.
     */
    override fun apply(string: String?): Any? {
        return string?.split(",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)".toRegex())
                ?.map { it.trim() }
                ?.filter { it.isNotEmpty() }
    }
}

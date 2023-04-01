// SPDX-License-Identifier: BSD-3-Clause
package org.islandoftex.texplate.model.handlers

import java.io.File

/**
 * Implements a file reader handler.
 *
 * @version 1.0.3
 * @since 1.0.3
 */
class FileReaderHandler : Handler {

    /**
     * Applies the conversion to the string.
     *
     * @param string The string denoting a file.
     * @return A list of strings from the file.
     */
    override fun apply(string: String?): Any? {
        return string?.let {
            val file = File(string)
            if (file.exists() && file.isFile)
                file.readLines()
            else null
        } ?: emptyList<String>()
    }
}

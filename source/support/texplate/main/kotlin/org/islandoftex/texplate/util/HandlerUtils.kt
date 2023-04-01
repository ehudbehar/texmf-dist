// SPDX-License-Identifier: BSD-3-Clause
package org.islandoftex.texplate.util

import org.islandoftex.texplate.model.handlers.BooleanHandler
import org.islandoftex.texplate.model.handlers.CSVListHandler
import org.islandoftex.texplate.model.handlers.FileReaderHandler
import org.islandoftex.texplate.model.handlers.Handler

/**
 * Provides the map of handlers.
 *
 * @version 1.0
 * @since 1.0
 */
object HandlerUtils {
    /**
     * Gets the map of handlers.
     *
     * @return Map of handlers.
     */
    @JvmStatic
    val handlers: Map<String, Handler> = mapOf(
            "to-csv-list" to CSVListHandler(),
            "to-boolean" to BooleanHandler(),
            "to-string-list-from-file" to FileReaderHandler()
    )
}

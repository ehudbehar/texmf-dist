// SPDX-License-Identifier: BSD-3-Clause
package org.islandoftex.texplate.util

import java.time.LocalDate

/**
 * Message helper methods.
 *
 * @version 1.0
 * @since 1.0
 */
object MessageUtils {
    // the message width
    private const val WIDTH = 60
    // the application version
    private val VERSION = MessageUtils::class.java.`package`.implementationVersion
            ?: "DEVELOPMENT BUILD"

    /**
     * Prints a line in the terminal, without a line break.
     *
     * @param message The message to be printed.
     */
    @JvmStatic
    fun line(message: String) {
        print("$message ".padEnd(WIDTH - " [FAILED]".length, '.') + " ")
    }

    /**
     * Prints the status in the terminal.
     *
     * @param result The boolean value.
     */
    @JvmStatic
    fun status(result: Boolean) {
        println(if (result) "[ DONE ]" else "[FAILED]")
    }

    /**
     * Prints the error in the terminal.
     *
     * @param throwable The throwable reference.
     */
    @JvmStatic
    fun error(throwable: Throwable) {
        println("\n" + "HOUSTON, WE'VE GOT A PROBLEM ".padEnd(WIDTH, '-') +
                "\n" + throwable.message + "\n" +
                "".padStart(WIDTH, '-') + "\n")
    }

    /**
     * Prints the application logo in the terminal.
     */
    fun drawLogo() {
        println(
                " ______         __   __          ___             __             \n" +
                        "/\\__  _\\       /\\ \\ /\\ \\        /\\_ \\           /\\ \\__          \n" +
                        "\\/_/\\ \\/    __ \\ `\\`\\/'/'  _____\\//\\ \\      __  \\ \\ ,_\\    __   \n" +
                        "   \\ \\ \\  /'__`\\`\\/ > <   /\\ '__`\\\\ \\ \\   /'__`\\ \\ \\ \\/  /'__`\\ \n" +
                        "    \\ \\ \\/\\  __/   \\/'/\\`\\\\ \\ \\L\\ \\\\_\\ \\_/\\ \\L\\.\\_\\ \\ \\_/\\  __/ \n" +
                        "     \\ \\_\\ \\____\\  /\\_\\\\ \\_\\ \\ ,__//\\____\\ \\__/.\\_\\\\ \\__\\ \\____\\\n" +
                        "      \\/_/\\/____/  \\/_/ \\/_/\\ \\ \\/ \\/____/\\/__/\\/_/ \\/__/\\/____/\n" +
                        "                             \\ \\_\\                              \n" +
                        "                              \\/_/                              \n"
        )
        println(
                "TeXplate $VERSION, a document structure creation tool\n" +
                        "Copyright (c) ${LocalDate.now().year}, Island of TeX\n" +
                        "All rights reserved.\n"
        )
    }
}

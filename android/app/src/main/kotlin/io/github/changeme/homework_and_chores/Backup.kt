package io.github.changeme.homework_and_chores

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import java.io.File

/**
 * Backups, Android side: copies files to and from what the user picked with
 * the system's file and folder pickers (Storage Access Framework), so the app
 * needs no storage permission. Snapshots, checks and merging happen in Dart;
 * see docs/design/data-safety.md.
 */
object Backup {
    // Not every provider knows a SQLite type; a generic one keeps the name.
    const val MIME = "application/octet-stream"

    fun createDocumentIntent(name: String) =
        Intent(Intent.ACTION_CREATE_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType(MIME)
            .putExtra(Intent.EXTRA_TITLE, name)

    fun openDocumentIntent() =
        Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("*/*")

    fun openFolderIntent() = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)

    /** Copies the file at [path] into the document at [uri]. */
    fun writeTo(context: Context, uri: Uri, path: String) {
        val out = context.contentResolver.openOutputStream(uri, "wt")
            ?: error("cannot write $uri")
        out.use { stream -> File(path).inputStream().use { it.copyTo(stream) } }
    }

    /** Copies the document at [uri] to [dest]. */
    fun readFrom(context: Context, uri: Uri, dest: File) {
        val input = context.contentResolver.openInputStream(uri)
            ?: error("cannot read $uri")
        dest.parentFile?.mkdirs()
        input.use { stream -> dest.outputStream().use { stream.copyTo(it) } }
    }

    /** Keeps read and write access to a picked folder across restarts. */
    fun keepFolder(context: Context, tree: Uri) {
        context.contentResolver.takePersistableUriPermission(
            tree,
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
        )
    }

    private fun folderDocument(tree: Uri) =
        DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))

    /** The folder's name, or null if it's gone or the permission was revoked. */
    fun folderName(context: Context, tree: Uri): String? {
        val permitted = context.contentResolver.persistedUriPermissions.any {
            it.uri == tree && it.isWritePermission
        }
        if (!permitted) return null
        return try {
            context.contentResolver.query(
                folderDocument(tree),
                arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null, null, null,
            )?.use { if (it.moveToFirst()) it.getString(0) else null }
        } catch (_: Exception) {
            null
        }
    }

    /** (document id, name) of the files directly in the folder. */
    private fun children(context: Context, tree: Uri): List<Pair<String, String>> {
        val uri = DocumentsContract.buildChildDocumentsUriUsingTree(
            tree, DocumentsContract.getTreeDocumentId(tree),
        )
        val columns = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
        )
        val result = mutableListOf<Pair<String, String>>()
        context.contentResolver.query(uri, columns, null, null, null)?.use {
            while (it.moveToNext()) result.add(it.getString(0) to it.getString(1))
        }
        return result
    }

    /** Writes the file at [path] into the folder as [name], replacing a file of that name. */
    fun writeToFolder(context: Context, tree: Uri, name: String, path: String) {
        val existing = children(context, tree).firstOrNull { it.second == name }
        val target = if (existing != null) {
            DocumentsContract.buildDocumentUriUsingTree(tree, existing.first)
        } else {
            DocumentsContract.createDocument(context.contentResolver, folderDocument(tree), MIME, name)
                ?: error("cannot create $name")
        }
        writeTo(context, target, path)
    }

    /**
     * Deletes the oldest files whose names start with [prefix] beyond the newest [keep].
     * Names carry the date (yyyy-mm-dd), so sorting by name sorts by age. Nothing else in
     * the folder is touched.
     */
    fun pruneFolder(context: Context, tree: Uri, prefix: String, keep: Int) {
        children(context, tree)
            .filter { it.second.startsWith(prefix) }
            .sortedByDescending { it.second }
            .drop(keep)
            .forEach {
                DocumentsContract.deleteDocument(
                    context.contentResolver,
                    DocumentsContract.buildDocumentUriUsingTree(tree, it.first),
                )
            }
    }
}

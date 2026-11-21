"""End-to-end sync check against a running Anki Sync Server.

usage: python client.py upload|download|login-bad URL USER PASS
upload:   new collection with a note and a media file, full upload + media sync
download: fresh collection, full download + media sync, prints what arrived
"""
import os, sys, tempfile
from anki.collection import Collection
from anki.sync import SyncOutput

mode, url, user, pw = sys.argv[1:5]
d = tempfile.mkdtemp()
col = Collection(os.path.join(d, "collection.anki2"))
if mode == "login-bad":
    try:
        col.sync_login(user, pw + "x", url)
        print("BAD: wrong password accepted"); sys.exit(1)
    except Exception as e:
        print("OK: wrong password rejected:", type(e).__name__); sys.exit(0)
auth = col.sync_login(user, pw, url)
print("login ok, hkey len", len(auth.hkey))
if mode == "upload":
    note = col.new_note(col.models.by_name("Basic"))
    note["Front"] = "railway-test-front"
    note["Back"] = 'railway-test-back <img src="railway.png">'
    col.add_note(note, col.decks.id("Default"))
    with open(os.path.join(col.media.dir(), "railway.png"), "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\nrailway-test-media")
out = col.sync_collection(auth, False)
print("sync required:", out.required, "server_media_usn", out.server_media_usn)
if out.required == SyncOutput.FULL_UPLOAD or (mode == "upload" and out.required == SyncOutput.FULL_SYNC):
    col.close_for_full_sync(); col.full_upload_or_download(auth=auth, server_usn=None, upload=True); col.reopen(after_full_sync=True)
    print("full upload done")
elif out.required in (SyncOutput.FULL_DOWNLOAD, SyncOutput.FULL_SYNC):
    col.close_for_full_sync(); col.full_upload_or_download(auth=auth, server_usn=None, upload=False); col.reopen(after_full_sync=True)
    print("full download done")
col.sync_media(auth)
import time
for _ in range(60):
    st = col.media_sync_status()
    if not st.active: break
    time.sleep(1)
print("notes:", col.note_count(), "fronts:", [col.get_note(n)["Front"] for n in col.find_notes("")])
print("media:", sorted(os.listdir(col.media.dir())))
col.close()

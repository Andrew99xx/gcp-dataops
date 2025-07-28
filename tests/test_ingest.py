import io
import zipfile
from unittest import mock

import requests

import ingest


def fake_zip_bytes():
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, mode="w") as z:
        z.writestr("data.json", '{"foo": "bar"}')
    return buf.getvalue()


@mock.patch("ingest.requests.get")
def test_download_and_extract(mock_get):
    # stub the HTTP response
    class Dummy:
        headers = {"content-length": str(len(fake_zip_bytes()))}

        def raise_for_status(self):
            pass

        def iter_content(self, chunk_size):
            yield fake_zip_bytes()

    mock_get.return_value = Dummy()

    name, data = ingest.download_and_extract(), None
    # No exception => success, and data contains our JSON blob
    assert b'"foo": "bar"' in ingest.download_and_extract()


@mock.patch("ingest.storage.Client")
def test_upload_to_gcs_retries(mock_client):
    # ensure upload_from_string gets called
    mock_bucket = mock_client.return_value.bucket.return_value
    blob = mock_bucket.blob.return_value
    blob.open.return_value.__enter__.return_value = io.BytesIO()

    # Should not raise
    ingest.upload_to_gcs("test.json", b"{}", "dummy-bkt", max_retries=1)
    blob.open.assert_called_once()

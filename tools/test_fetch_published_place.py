import json
import unittest

from fetch_published_place import _cdn_url, fetch


class Response:
    headers = {}

    def __init__(self, data):
        self.data = data

    def __enter__(self):
        return self

    def __exit__(self, *_):
        return False

    def read(self, *_):
        return self.data


class FetchPublishedPlaceTests(unittest.TestCase):
    def test_downloads_only_a_roblox_place_from_the_returned_cdn(self):
        seen = []
        def opener(request, timeout):
            seen.append(request.full_url)
            if len(seen) == 1:
                self.assertEqual(request.get_header('X-api-key'), 'test-key')
                return Response(json.dumps({'location': 'https://c0.rbxcdn.com/abc'}).encode())
            return Response(b'<roblox version="4"></roblox>')
        content, extension = fetch(99438308921556, 'test-key', opener)
        self.assertEqual(extension, '.rbxlx')
        self.assertEqual(content, b'<roblox version="4"></roblox>')
        self.assertEqual(seen, ['https://apis.roblox.com/asset-delivery-api/v1/assetId/99438308921556', 'https://c0.rbxcdn.com/abc'])

    def test_rejects_unexpected_asset_hosts(self):
        for url in ('http://c0.rbxcdn.com/file', 'https://rbxcdn.com.evil.test/file', 'https://evil.test/file'):
            with self.assertRaises(ValueError):
                _cdn_url(url)


if __name__ == '__main__':
    unittest.main()

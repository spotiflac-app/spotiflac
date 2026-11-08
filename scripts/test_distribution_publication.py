"""Exercise publication boundaries without changing a real GitHub release."""
import base64
import copy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from urllib.error import HTTPError

from publish_distribution import publish_verified_release


class PublicationTest(unittest.TestCase):
    def setUp(self):
        directory=tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root=Path(directory.name)
        self.repo='spotiflac-app/spotiflac-releases'
        self.ipa=self.root/'SpotiFLAC-v5.2.7-ios-unsigned.ipa'
        self.ipa.write_bytes(b'verified IPA fixture')
        self.feed=self.root/'apps.json'
        self.feed.write_text(json.dumps({'name':'SpotiFLAC Source','apps':[{
            'downloadURL':f'https://github.com/{self.repo}/releases/download/v5.2.7/{self.ipa.name}',
            'size':self.ipa.stat().st_size,
        }]}))
        self.paths=[self.ipa,self.feed]
        self.release={'id':17,'draft':True,'prerelease':False,'tag_name':'v5.2.7','assets':[
            {'name':p.name,'size':p.stat().st_size,'digest':'sha256:'+hashlib.sha256(p.read_bytes()).hexdigest()}
            for p in self.paths
        ]}

    def api(self):
        test=self
        class API:
            def __init__(self):
                self.release=copy.deepcopy(test.release)
                self.calls=[]
                self.feed=None
                self.fail_feed_once=False

            def api(self,method,path,data=None):
                self.calls.append((method,path,copy.deepcopy(data)))
                if not path.startswith(f'/repos/{test.repo}/'):
                    raise AssertionError('Publication escaped the downloads repository')
                if '/releases/' in path:
                    if method=='GET':return copy.deepcopy(self.release)
                    if method=='PATCH':
                        self.release.update(data)
                        return copy.deepcopy(self.release)
                if path.endswith('/contents/apps.json'):
                    if method=='GET':
                        if self.feed is None:raise HTTPError(path,404,'missing',{},None)
                        return {'sha':'current-feed-sha','content':self.feed}
                    if method=='PUT':
                        if self.fail_feed_once:
                            self.fail_feed_once=False
                            raise OSError('temporary feed write failure')
                        self.feed=data['content']
                        return {'content':{'sha':'new-feed-sha'}}
                raise AssertionError((method,path))
        return API()

    def publish(self,api):
        return publish_verified_release(api,self.repo,self.release,self.paths,'v5.2.7',self.feed)

    def test_publication_and_feed_use_only_the_verified_downloads_repository(self):
        api=self.api()
        result=self.publish(api)
        self.assertFalse(result['draft'])
        self.assertEqual(base64.b64decode(api.feed),self.feed.read_bytes())
        self.assertEqual([m for m,_,_ in api.calls],['GET','PATCH','GET','PUT'])

    def test_missing_tampered_or_extra_asset_blocks_publication(self):
        for failure in ['missing','tampered','extra']:
            with self.subTest(failure=failure):
                api=self.api()
                if failure=='missing':api.release['assets'].pop()
                elif failure=='tampered':api.release['assets'][0]['digest']='sha256:'+'0'*64
                else:api.release['assets'].append({'name':'unexpected','digest':'sha256:'+'0'*64})
                with self.assertRaisesRegex(ValueError,'assets do not match'):
                    self.publish(api)
                self.assertFalse(any(m in ('PATCH','PUT') for m,_,_ in api.calls))

    def test_wrong_feed_host_blocks_publication_before_mutation(self):
        data=json.loads(self.feed.read_text())
        data['apps'][0]['downloadURL']=data['apps'][0]['downloadURL'].replace(self.repo,'spotiflac-app/spotiflac')
        self.feed.write_text(json.dumps(data))
        self.release['assets'][1]['digest']='sha256:'+hashlib.sha256(self.feed.read_bytes()).hexdigest()
        self.release['assets'][1]['size']=self.feed.stat().st_size
        api=self.api()
        with self.assertRaisesRegex(ValueError,'outside the published downloads'):
            self.publish(api)
        self.assertFalse(any(m in ('PATCH','PUT') for m,_,_ in api.calls))

    def test_feed_retry_does_not_modify_an_already_published_release(self):
        api=self.api();api.fail_feed_once=True
        with self.assertRaises(OSError):self.publish(api)
        self.assertFalse(api.release['draft'])
        self.publish(api)
        self.assertEqual(sum(m=='PATCH' for m,_,_ in api.calls),1)
        self.assertEqual(base64.b64decode(api.feed),self.feed.read_bytes())

    def test_preview_publication_does_not_replace_stable_feed(self):
        self.release['prerelease']=True
        api=self.api()
        self.publish(api)
        self.assertIsNone(api.feed)
        self.assertEqual([m for m,_,_ in api.calls],['GET','PATCH'])


if __name__=='__main__':unittest.main()

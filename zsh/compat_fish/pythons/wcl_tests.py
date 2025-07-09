import unittest

import pytest

from wcl import clone_url, parse_repo, relative_repo_dir

class TestMapToRepoDir(unittest.TestCase):

    def test_github(self):
        repo_dir = relative_repo_dir(parse_repo('git@github.com:g0t4/dotfiles.git'))
        self.assertEqual(repo_dir, 'github/g0t4/dotfiles')

    def test_bitbucket(self):
        repo_dir = relative_repo_dir(parse_repo('git@bitbucket.org:g0t4/dotfiles.git'))
        self.assertEqual(repo_dir, 'bitbucket/g0t4/dotfiles')

    def test_gitlab(self):
        repo_dir = relative_repo_dir(parse_repo('git@gitlab.com:g0t4/dotfiles.git'))
        self.assertEqual(repo_dir, 'gitlab/g0t4/dotfiles')

    def test_repo_only(self):
        repo_dir = relative_repo_dir(parse_repo('dotfiles'))
        self.assertEqual(repo_dir, 'github/g0t4/dotfiles')

    def test_org_repo_only(self):
        repo_dir = relative_repo_dir(parse_repo('g0t4/dotfiles'))
        self.assertEqual(repo_dir, 'github/g0t4/dotfiles')

    def test_sourceware_org(self):
        repo_dir = relative_repo_dir(parse_repo('https://sourceware.org/git/glibc.git'))
        self.assertEqual(repo_dir, 'sourceware.org/git/glibc')

    def test_trailing_slash(self):
        repo_dir = relative_repo_dir(parse_repo('https://github.com/Hammerspoon/Spoons/'))
        self.assertEqual(repo_dir, 'github/Hammerspoon/Spoons')

@pytest.mark.parametrize(
    "input_url, expected_url",
    [
        pytest.param('git@github.com:g0t4/dotfiles.git', 'git@github.com:g0t4/dotfiles', id="test_github_uses_git"),  # drop .git
        pytest.param('https://github.com/g0t4/dotfiles.git', 'git@github.com:g0t4/dotfiles', id="test_https_uses_git"),  # drop .git
        pytest.param('https://sourceware.org/git/glibc.git', 'https://sourceware.org/git/glibc', id="test_sourceware_uses_https"),
        pytest.param('https://huggingface.co/g0t4/dotfiles', 'https://huggingface.co/g0t4/dotfiles', id="test_huggingface_uses_https"),
    ])
def test_clone_url_normalization(input_url, expected_url):
    url = clone_url(parse_repo(input_url))
    assert url == expected_url

@pytest.mark.parametrize(
    "repo_location, expected_domain, expected_repo",
    [

        # general
        pytest.param('https://gitlab.com/g0t4/dotfiles.git', 'gitlab.com', 'g0t4/dotfiles', id="test_https_dotgit_suffix"),
        pytest.param('  https://gitlab.com/g0t4/dotfiles.git   ', 'gitlab.com', 'g0t4/dotfiles', id="test_space_padding_ignores"),

        # github
        pytest.param('https://github.com/g0t4/dotfiles', 'github.com', 'g0t4/dotfiles', id="test_github_https"),
        pytest.param('git@github.com:g0t4/dotfiles.git', 'github.com', 'g0t4/dotfiles', id="test_github_ssh"),
        # PRN map githubusercontent.com => github
        # pytest.param('https://raw.githubusercontent.com/g0t4/dotfiles/master/git/linux.gitconfig', 'github.com', 'g0t4/dotfiles', id="test_githubusercontent.com => github.com"),

        # huggingface
        pytest.param('https://huggingface.co/microsoft/speecht5_tts', 'huggingface.co', 'microsoft/speecht5_tts', id="test_huggingface_https"),
        # git@hf.co:microsoft/speecht5_tts
        # https://huggingface.co/microsoft/speecht5_tts
        #   PRN https+hf.co?
        #   PRN git@huggingface.co?

        # bitbucket
        pytest.param('https://bitbucket.org/g0t4/dotfiles', 'bitbucket.org', 'g0t4/dotfiles', id="test_bitbucket_https"),
        pytest.param('git@bitbucket.org:g0t4/dotfiles.git', 'bitbucket.org', 'g0t4/dotfiles', id="test_bitbucket_ssh"),

        # sourceware
        pytest.param('https://sourceware.org/git/glibc.git', 'sourceware.org', 'git/glibc', id="test_sourceware_org_https"),

        # gitlab
        pytest.param('https://gitlab.com/g0t4/dotfiles', 'gitlab.com', 'g0t4/dotfiles', id="test_gitlab_https"),
        pytest.param('git@gitlab.com:g0t4/dotfiles.git', 'gitlab.com', 'g0t4/dotfiles', id="test_gitlab_ssh"),

        # non-URL locations
        pytest.param('dotfiles', 'github.com', 'g0t4/dotfiles', id="test_repoOnly_assumes_github_g0t4"),
        pytest.param('g0t4/dotfiles', 'github.com', 'g0t4/dotfiles', id="test_orgRepoOnly_assumes_github_g0t4"),

        # ignore path after repo location
        pytest.param('https://github.com/g0t4/dotfiles/blob/master/git/linux.gitconfig', 'github.com', 'g0t4/dotfiles', id="test_ignore_path_after_repo_location"),
        #
        pytest.param('https://huggingface.co/datasets/PleIAs/common_corpus', 'huggingface.co', 'datasets/PleIAs/common_corpus', id="hf three level repo"),
        pytest.param('https://huggingface.co/datasets/PleIAs/common_corpus/tree/main', 'huggingface.co', 'datasets/PleIAs/common_corpus', id="hf three level repo w/ blob"),
        pytest.param('https://huggingface.co/datasets/PleIAs/common_corpus/blob/main/README.md', 'huggingface.co', 'datasets/PleIAs/common_corpus', id="hf three level repo w/ blob + file"),

        # TODO impl later, if I care to, currently broken
        # TODO turn into some special case for github that never allows for more than org/repo
        # pytest.param('https://github.com/foo/bar/pulls', 'github.com', 'foo/bar', id="github pulls should not be seen as repo"),
        # pytest.param('https://github.com/foo/bar/issues', 'github.com', 'foo/bar', id="github issues should not be seen as repo"),
    ])
def test_parse_repo(repo_location, expected_domain, expected_repo):
    parsed = parse_repo(repo_location)
    assert parsed is not None
    assert parsed.domain == expected_domain
    assert parsed.repo == expected_repo

# TODO support hg (mercurial)?
#  hg.nginx.org/nginx
#  hg.nginx.org/nginx.org

if __name__ == '__main__':
    # don't port everything, just run both sets
    import sys
    pytest.main([sys.argv[0]])

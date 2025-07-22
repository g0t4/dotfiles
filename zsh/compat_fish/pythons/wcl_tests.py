import pytest

from wcl import clone_url, parse_repo, relative_repo_dir

@pytest.mark.parametrize(
    "input_url, expected_url",
    [
        pytest.param('git@github.com:g0t4/dotfiles.git', 'github/g0t4/dotfiles', id="test_github"),
        pytest.param('git@bitbucket.org:g0t4/dotfiles.git', 'bitbucket/g0t4/dotfiles', id="test_bitbucket"),
        pytest.param('git@gitlab.com:g0t4/dotfiles.git', 'gitlab/g0t4/dotfiles', id="test_gitlab"),
        pytest.param('dotfiles', 'github/g0t4/dotfiles', id="test_repo_only"),
        pytest.param('g0t4/dotfiles', 'github/g0t4/dotfiles', id="test_org_repo_only"),
        pytest.param('https://sourceware.org/git/glibc.git', 'sourceware.org/git/glibc', id="test_sourceware_org"),
        pytest.param('https://github.com/Hammerspoon/Spoons/', 'github/Hammerspoon/Spoons', id="test_trailing_slash"),  # trailing slash
    ])
def test_map_to_repo_dir(input_url, expected_url):
    repo_dir = relative_repo_dir(parse_repo(input_url))
    assert repo_dir == expected_url

@pytest.mark.parametrize(
    "input_url, expected_url",
    [
        pytest.param('git://github.com/g0t4/dotfiles', 'git@github.com:g0t4/dotfiles', id="unauthenticated git:// => use git@ ssh"),
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

        # git://git.sv.gnu.org => gnu.org's cgit server
        pytest.param('git://git.sv.gnu.org/sed', 'cgit.git.savannah.gnu.org', 'cgit/sed', id="git.sv.gnu.org/sed => cgit"),
        pytest.param('git://git.savannah.gnu.org/sed', 'cgit.git.savannah.gnu.org', 'cgit/sed', id="git.savannah.gnu.org/sed => cgit"),

        # non-URL locations
        pytest.param('dotfiles', 'github.com', 'g0t4/dotfiles', id="test_repoOnly_assumes_github_g0t4"),
        pytest.param('g0t4/dotfiles', 'github.com', 'g0t4/dotfiles', id="test_orgRepoOnly_assumes_github_g0t4"),

        # ignore path after repo location
        pytest.param('https://github.com/g0t4/dotfiles/blob/master/git/linux.gitconfig', 'github.com', 'g0t4/dotfiles', id="test_ignore_path_after_repo_location"),
        #
        pytest.param('https://huggingface.co/datasets/PleIAs/common_corpus', 'huggingface.co', 'datasets/PleIAs/common_corpus', id="hf three level repo"),
        pytest.param('https://huggingface.co/datasets/PleIAs/common_corpus/tree/main', 'huggingface.co', 'datasets/PleIAs/common_corpus', id="hf three level repo w/ blob"),
        pytest.param('https://huggingface.co/datasets/PleIAs/common_corpus/blob/main/README.md', 'huggingface.co', 'datasets/PleIAs/common_corpus', id="hf three level repo w/ blob + file"),

        # TODO add more testing of two vs three+ components to repo namespace
        pytest.param('https://github.com/foo/bar/pulls', 'github.com', 'foo/bar', id="github pulls with nothing after pulls"),
        pytest.param('https://github.com/foo/bar/pulls/1', 'github.com', 'foo/bar', id="github pulls/1 should not be seen as repo"),
        pytest.param('https://github.com/foo/bar/issues', 'github.com', 'foo/bar', id="github issues with nothing after issues"),
        pytest.param('https://github.com/foo/bar/issues/1', 'github.com', 'foo/bar', id="github issues/1 should not be seen as repo"),
        #
        pytest.param('https://github.com/foo/pulls/pulls', 'github.com', 'foo/pulls', id="github pulls in repo name should not be filtered out"),
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
    import sys
    pytest.main([sys.argv[0]])

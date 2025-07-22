{
    fetchurl
}:

{
    owner,
    repo,
    tag,
    file,
    hash,

    githubHost ? "github.com",

    ...
} @ args:

fetchurl {
    url = "https://${githubHost}/${owner}/${repo}/releases/download/${tag}/${file}";
    inherit hash;
} // args

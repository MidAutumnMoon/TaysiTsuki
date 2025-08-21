{
    lib,
    fetchurl
}:

{
    owner,
    repo,
    tag,
    file,

    githubHost ? "github.com",

    ...
} @ args:

fetchurl <| (a: b: a // b)
    {
        url = "https://${githubHost}/${owner}/${repo}/releases/download/${tag}/${file}";
    }
    <| lib.removeAttrs args [
        "owner" "repo" "tag" "file" "githubHost"
    ]

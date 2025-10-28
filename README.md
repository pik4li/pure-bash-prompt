# a pure bash prompt

Pure bash prompt with git integration, docker compose project detection and
diskspace analyzer direcly in pure bash

Inspired by [krashikiworks/pure-prompt-bash](https://github.com/krashikiworks/pure-prompt-bash)

<details>
<summary>Preview</summary>

- **disk-analyzer**:
> has color values for 'above 50%', 'below 50%', and 'below threshhold' <- the
> threshhold is configurable via a VARIABLE

![disk-analyzer](assets/disk-analyzer.png)

- **git-status**:

<!-- ![git-status](assets/git-status.png) -->
![git-status](assets/git-status.pure-prompt.gif)

- **docker-status** (ssh):
> note that the `hostname` gets also displayed along the `username`, when connecting
> via **ssh**

![docker-showcase](assets/docker-status.pure-prompt.gif)

<!-- ![docker-showcase-up-one](assets/docker-showcase-up.png) -->
<!---->
<!-- ![docker-showcase-up-more](assets/docker-showcase-up-more.png) -->

</details>

## Install

just clone this repository (or just copy pure.bash) anywhere, and add

```bash
source /path/to/pure.bash
```

to your `.bashrc`

## settings

You can set some settings in the prompt file itself:

| key | default_value | properties |
| - | - | - |
| `ENABLE_DOCKER` | `true` | Enables or disables the docker line |
| `ENABLE_GIT` | `true` | Enables or disables the git widget |
| `ENABLE_SSH`  | `true` | Enables the ssh detection with hostname prefix for ssh sessions |
| `ENABLE_DISKSPACE` | `true` | Enables the diskspace widget |

## Uninstall

just remove what you downloaded, and delete `source` command from your `.bashrc`

## License

MIT License. See LICENSE.

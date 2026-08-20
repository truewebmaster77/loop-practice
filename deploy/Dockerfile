# The build loop's runner, contained.
#
# Everything the loop needs lives in here: Node, git, the GitHub CLI, the agent
# CLIs and a GitHub Actions runner. The host keeps none of it. On a box that
# also has a desktop you remote into, that separation is the point — a runaway
# test suite or a bad dependency from someone's branch should not be able to
# reach your browser profile, your SSH keys or your files.

FROM mcr.microsoft.com/playwright:v1.50.0-jammy

ARG RUNNER_VERSION=2.322.0

# Never root. A container running as root shares uid 0 with the host kernel,
# and any escape lands you somewhere you did not want to be.
RUN useradd -m -s /bin/bash runner

RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates git jq unzip sudo \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

USER runner
WORKDIR /home/runner

RUN mkdir actions-runner && cd actions-runner \
 && curl -fsSL -o runner.tar.gz \
      "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
 && tar xzf runner.tar.gz && rm runner.tar.gz

# The agent CLIs. Their sign-ins are NOT baked in — they arrive at run time on a
# mounted volume, so the image carries no credentials and can be rebuilt freely.
RUN curl -fsSL https://claude.ai/install.sh | bash || true
RUN npm i -g @openai/codex || true

COPY --chown=runner:runner entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

ENTRYPOINT ["/home/runner/entrypoint.sh"]

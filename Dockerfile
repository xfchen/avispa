FROM heroku/heroku:18

ENV LANG C.UTF-8

ENV stack='stack --resolver lts-11.22'

# Install required packages.
RUN apt-get update
RUN apt-get upgrade -y --assume-yes --allow-unauthenticated
# Install packages for stack and ghc.
RUN apt-get install -y --assume-yes --allow-unauthenticated xz-utils gcc libgmp-dev zlib1g-dev
# Install packages needed for libraries used by our app.
RUN apt-get install -y --assume-yes --allow-unauthenticated libpq-dev
# Install convenience utilities, like tree, ping, and vim.
RUN apt-get install -y --assume-yes --allow-unauthenticated tree iputils-ping vim-nox

# Remove apt caches to reduce the size of our container.
RUN rm -rf /var/lib/apt/lists/*

# Install stack to /opt/stack/bin.
RUN mkdir -p /opt/stack/bin
RUN curl -L https://www.stackage.org/stack/linux-x86_64 | tar xz --wildcards --strip-components=1 -C /opt/stack/bin '*/stack'

# Create /opt/avispa/bin and /opt/avispa/src.  Set
# /opt/avispa/src as the working directory.
RUN mkdir -p /opt/avispa/src
RUN mkdir -p /opt/avispa/bin
WORKDIR /opt/avispa/src

# Set the PATH for the root user so they can use stack.
ENV PATH "$PATH:/opt/stack/bin:/opt/avispa/bin"

# Install GHC using stack, based on your app's stack.yaml file.
COPY ./stack.yaml /opt/avispa/stack.yaml
RUN stack --no-terminal setup

# Install all dependencies in app's .cabal file.
COPY ./avispa.cabal /opt/avispa/avispa.cabal
RUN stack --no-terminal test --only-dependencies

# Build application.
COPY . /opt/avispa
RUN stack --no-terminal build

# Install application binaries to /opt/avispa/bin.
RUN stack --no-terminal --local-bin-path /opt/avispa/bin install

# Remove source code.
#RUN rm -rf /opt/avispa/src

# Add the apiuser and setup their PATH.
RUN useradd -ms /bin/bash apiuser
RUN chown -R apiuser:apiuser /opt/avispa
USER apiuser
ENV PATH "$PATH:/opt/stack/bin:/opt/avispa/bin"

# Set the working directory as /opt/avispa/.
WORKDIR /opt/avispa

CMD /opt/avispa/bin/avispa

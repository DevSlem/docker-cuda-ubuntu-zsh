# Use the base image
FROM nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04

# Set environment variable to disable interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    vim \
    sudo \
    curl \
    git \
    zsh \
    openssh-server \
    tmux \
    libncurses5-dev \
    locales \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y

# Generate and configure locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Set environment variables for locale
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# SSH authentication setting
RUN mkdir /var/run/sshd && \
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Expose SSH port
EXPOSE 22

# Set root as the default user
WORKDIR /root

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended

# Install Auto Suggestions plugin
RUN git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Install Syntax Highlighting plugin
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install Powerlevel10k theme
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

# Configure .zshrc
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc && \
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc && \
    echo "source ~/.zshrc" >> ~/.bashrc

# Copy pre-configured .p10k.zsh file into the container (optional)
COPY .p10k.zsh /root/.p10k.zsh

# Update .zshrc to source .p10k.zsh (optional)
RUN echo "source ~/.p10k.zsh" >> ~/.zshrc

# Explicitly set SHELL environment variable to zsh
ENV SHELL=/usr/bin/zsh

# Install Miniconda3
RUN mkdir -p ~/miniconda3 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh && \
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 && \
    rm ~/miniconda3/miniconda.sh && \
    echo "export PATH=~/miniconda3/bin:\$PATH" >> ~/.bashrc && \
    echo "export PATH=~/miniconda3/bin:\$PATH" >> ~/.zshrc && \
    ~/miniconda3/bin/conda init --all && \
    ~/miniconda3/bin/conda config --set auto_activate_base false

# Add conda environment variable settings to ~/.zshrc
RUN echo 'export PATH="/root/miniconda3/envs/$CONDA_DEFAULT_ENV/bin:$PATH"' >> ~/.zshrc && \
    echo 'if [[ -n "$CONDA_DEFAULT_ENV" ]]; then' >> ~/.zshrc && \
    echo '    export PATH="/root/miniconda3/envs/$CONDA_DEFAULT_ENV/bin:$PATH"' >> ~/.zshrc && \
    echo 'fi' >> ~/.zshrc

# Set root's default shell to zsh
RUN chsh -s /usr/bin/zsh root

# Copy test script
RUN mkdir -p /root/test
COPY torch_test.py /root/test/torch_test.py

ARG SSH_PUBLIC_KEY=""
RUN mkdir -p /root/.ssh && \
    echo "${SSH_PUBLIC_KEY}" > /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys && \
    chmod 700 /root/.ssh

# Start SSH service and ZSH shell by default
CMD ["/bin/bash", "-c", "/usr/sbin/sshd -D & zsh"]

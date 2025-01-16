
if [ -f ~/.bashrc ]; then
   source ~/.bashrc
fi

complete -C /opt/homebrew/Cellar/tfenv/3.0.0/versions/1.2.0/terraform terraform
. "$HOME/.cargo/env"

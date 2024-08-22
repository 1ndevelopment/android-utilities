pkg install zsh lsd git
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
sed -i 's/^ZSH_THEME=.*$/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
echo "alias ls='lsd'" >> ~/.zshrc
echo "alias speedtest='speedtest-go'" >> ~/.zshrc
echo "alias biggest='du . -ah | sort -hr | head -n $1'" >> ~/.zshrc
git clone https://github.com/adi1090x/termux-style
cd termux-style
./install
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
sed -i 's/plugins=(\(git\))/plugins=(\n    \1\n    zsh-autosuggestions\n)/' ~/.zshrc

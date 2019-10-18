export NEWT_COLORS='
    root=white,gray
    border=black,lightgray
    window=lightgray,lightgray
    shadow=black,gray
    title=black,lightgray
    button=black,cyan
    actbutton=white,cyan
    compactbutton=black,lightgray
    checkbox=black,lightgray
    actcheckbox=lightgray,cyan
    entry=black,lightgray
    disentry=gray,lightgray
    label=black,lightgray
    listbox=black,lightgray
    actlistbox=black,cyan
    sellistbox=lightgray,black
    actsellistbox=lightgray,black
    textbox=gray,lightgray
    acttextbox=black,cyan
    emptyscale=,gray
    fullscale=,cyan
    helpline=white,black
    roottext=lightgrey,black
'
modules=(./modules/*.sh)
declare -a array

for m in "${modules[@]}"
do
    array+=($(basename $m) "$(cat $m | sed '2q;d' | cut -c2- )" OFF)
done

choices=$(whiptail --title "Additional Features" --checklist \
"Please choose any additional features you want to have installed." 20 78 4 \
"${array[@]}" 3>&1 1>&2 2>&3)

echo "Choices are: $choices"
echo
echo

for module in $choices; do
    fn=$(echo $module | xargs )
    echo "the next file is ${fn}"
    cat "modules/$fn"
done

echo ""
echo "=============================="
echo ""
cd /dev/block/by-name/
for f in *; do
    if [ -L "$f" ]; then
        echo "$(pwd)/$(basename "$f") -> $(readlink "$f")"
    else
        echo "$(pwd)/$(basename "$f")"
    fi
done
echo ""
echo "=============================="
echo ""
cd /dev/block/mapper/
for f in *; do
    if [ -L "$f" ]; then
        echo "$(pwd)/$(basename "$f") -> $(readlink "$f")"
    else
        echo "$(pwd)/$(basename "$f")"
    fi
done
echo ""
echo "=============================="
echo ""
cd /dev/block/platform/bootdevice/by-name/
for f in *; do
    if [ -L "$f" ]; then
        echo "$(pwd)/$(basename "$f") -> $(readlink "$f")"
    else
        echo "$(pwd)/$(basename "$f")"
    fi
done
echo ""
echo "=============================="
echo ""


clear
cd build
rm ./fstl.app/Contents/MacOS/fstl
cmake -DCMAKE_PREFIX_PATH=/usr/local/Cellar/qt/5.15.0/ ..
make -j8
cd ..
./build/fstl.app/Contents/MacOS/fstl ~/Desktop/3DFiles/LegoMan.step

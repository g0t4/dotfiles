# generic build: readme.md

	# build the project
	cmake -B build
	cmake --build build -j --config Release

	# transcribe an audio file
	./build/bin/whisper-cli -f samples/jfk.wav


## CUDA readme.md

	cmake -B build -DGGML_CUDA=1
	cmake --build build -j --config Release


## attempt HIPBLAS with whisper.cpp
	ggml supports hipblas, I searched for GGML_CUDA and also found GGML_HIPBLAS, seem to be alternatives

	cmake -B build -DGGML_HIPBLAS=1
		# cmake output only indicates x86 cpu... try gfx?

	cmake --build build -j --config Release



## LETS TRY with ggml's docs
	# GGML BUILD:
		cmake -DCMAKE_C_COMPILER="$(hipconfig -l)/clang" -DCMAKE_CXX_COMPILER="$(hipconfig -l)/clang++" -DGGML_HIP=ON

	# my idea for GGML HIPBLAS:

		# activate hipcc "env"
		set PATH /opt/rocm/bin $PATH
		# -- fixes missing -lamdhip64 error
		set LIBRARY_PATH /opt/rocm/lib $LIBRARY_PATH
		export LIBRARY_PATH
		set LD_LIBRARY_PATH /opt/rocm/lib $LD_LIBRARY_PATH
		export LD_LIBRARY_PATH
		set CPATH /opt/rocm/include $CPATH
		export CPATH
		export LDFLAGS="-L/opt/rocm/lib"

		rm -rf build # get rid of full dir first

		cmake -B build -DCMAKE_C_COMPILER="$(hipconfig -l)/clang" \
			-DCMAKE_CXX_COMPILER="$(hipconfig -l)/clang++" \
			-DGGML_HIP=ON \
			-DCMAKE_HIP_COMPILER_ROCM_ROOT=/opt/rocm

			# yay says:
				Including HIP backend

			# added -DCMAKE_HIP_COMPILER_ROCM_ROOT=/opt/rocm => b/c it was building this RCOM_ROOT wrong... this could be an issue later too?

            FYI did not need these, just had notes to try

                TODO add GGML_HIPBLAS=1?
                    ag GGML_HIP CMakeLists.txt #  looks like just _HIP needed?

                TODO TRY?  (did not need, yet)
                    -DAMDGPU_TARGETS="gfx" -DGGML_HIPBLAS=ON
                    from: https://github.com/ggml-org/whisper.cpp/issues/2202#issuecomment-2227107601


		cmake --build build -j --config Release
			# mentions built: ggml-cpu, ggml-hip*** (yay?)

		./build/bin/whisper-cli -f samples/jfk.wav
            # WORKS!!

## benchmarks

initial test of samle jfk audio was approx 350ms both for rocm AMD GPU and m1 max CoreML
	first coreml apple silicon run takes 3s b/c has to compile (IIUC) model IIRC

https://github.com/ggml-org/whisper.cpp

```
whisper-bench # check encoder timings alone

sh ./models/download-ggml-model.sh large-v3

# check audio file processing timing
# runs on all models downloaded
python3 scripts/bench.py -f samples/jfk.wav --threads 2,4,8 --processors 1,2

# wow ROCm support is faster on large-v3 than apple silicon!
#    ROCm => 1780ms, m1 => 2200ms+ for jfk wav file

```

## model download

models/download-ggml-model.sh


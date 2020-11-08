.PHONY: all clean
all: release.png debug.png release_log.png debug_log.png
clean:
	rm -f *.png
release.png: release.csv
	python3 ../tool/draw_graph.py $^ $@ '(release)' normal
debug.png: debug.csv
	python3 ../tool/draw_graph.py $^ $@ '(debug)' normal
release_log.png: release.csv
	python3 ../tool/draw_graph.py $^ $@ '(release/log)' log
debug_log.png: debug.csv
	python3 ../tool/draw_graph.py $^ $@ '(debug/log)' log

.PHONY: all clean
all: release.png debug.png
clean:
	rm -f *.png
release.png: release.csv
	python3 ../tool/draw_graph.py $^ $@ '(release)'

debug.png: debug.csv
	python3 ../tool/draw_graph.py $^ $@ '(debug)'
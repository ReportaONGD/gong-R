for image in admin agentes cuadro_mando financiaciones info inicio proyectos salir socios; 
do 
convert +contrast ${image}.org.png ${image}.seleccionado.png;
convert +contrast ${image}.seleccionado.png ${image}.seleccionado.png;
convert +contrast ${image}.seleccionado.png ${image}.seleccionado.png;
convert -modulate 130% ${image}.seleccionado.png ${image}.seleccionado.png;  
convert -modulate 45% ${image}.org.png ${image}.png; 
done

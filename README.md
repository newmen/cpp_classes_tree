#cpp_classes_tree
Создаёт графы наследования классов в C++ проекте.

Результат работы программы должен выглядеть похожим на то, что показанно на рисунке [examples/classes_tree.png](https://github.com/newmen/cpp_classes_tree/blob/master/examples/classes_tree.png).

## Как этим пользоваться?
Необходимо склонить сие себе, а затем запускать командой: `ruby main.rb -r -d путь_до_c++_проекта`. Указывая название png файла, расширение png указывать не нужно. Картинка с графами будет создана в папке проекта.

## Что нужно, чтобы заработало?
Нужно установить необходимые гемы, командой `bundle install`, выполненной в директории с данным проектом.

Для того чтобы гем, рисующий графы, таки начал рисовать картинки графов, нужно поставить **graphviz** в вашу систему. Например на ubuntu, следует выполнить команду `sudo apt-get install graphviz`.

### Недостатки
Графопостроитель:

- не различает виртуального наследования и обычного, и рисует их одинаково;
- не различает public, protected, private наследования, и рисует их одинаково;
- не различает шаблонов, обрезая определение шаблонного класса до названия класса, без параметров шаблона (если происходит наследование от шаблонного класса);

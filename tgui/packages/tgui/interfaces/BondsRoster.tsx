import { Box, Icon, NoticeBox, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Person = {
  name: string;
  job: string;
  self: number | boolean;
};

type Rank = {
  label: string;
  level: number;
  people: Person[];
};

type Block = {
  id: string;
  name: string;
  accent: string;
  icon: string;
  ranks: Rank[];
  total: number;
};

type Data = {
  own: Block | null;
  ally: Block | null;
  allyWarmth: number;
};

function RosterBlock(props: { block: Block; subtitle?: string }) {
  const { block, subtitle } = props;

  return (
    <Section
      title={
        <Box inline color={block.accent} bold>
          <Icon name={block.icon} mr={1} />
          {block.name}
        </Box>
      }
    >
      {!!subtitle && (
        <Box opacity={0.6} mb={1}>
          {subtitle}
        </Box>
      )}
      {!block.ranks.length && (
        <Box opacity={0.6}>Сейчас никого нет на месте.</Box>
      )}
      <Stack vertical>
        {block.ranks.map((rank, index) => (
          <Stack.Item key={index}>
            <Box bold opacity={0.75}>
              {rank.label}
            </Box>
            {rank.people.map((person, personIndex) => (
              <Box key={personIndex} ml={1}>
                <Box inline bold={!!person.self}>
                  {person.name}
                </Box>
                <Box inline ml={1} opacity={0.55}>
                  {person.job}
                </Box>
                {!!person.self && (
                  <Box inline ml={1} color={block.accent}>
                    — это вы
                  </Box>
                )}
              </Box>
            ))}
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
}

export const BondsRoster = () => {
  const { data } = useBackend<Data>();
  const { own, ally, allyWarmth = 0 } = data;

  return (
    <Window title="Лист фракции" width={560} height={680}>
      <Window.Content scrollable style={{ backgroundImage: 'none' }}>
        {!own && <NoticeBox>Вы ни к кому не приписаны.</NoticeBox>}
        <Stack vertical fill>
          {!!own && (
            <Stack.Item>
              <RosterBlock
                block={own}
                subtitle={`Всего на месте: ${own.total}`}
              />
            </Stack.Item>
          )}
          {!!ally && (
            <Stack.Item>
              <RosterBlock
                block={ally}
                subtitle={`Ближайшие союзники · расположение ${allyWarmth}`}
              />
            </Stack.Item>
          )}
          {!!own && !ally && (
            <Stack.Item>
              <NoticeBox>
                Союзников, к кому стоило бы обратиться, сейчас нет.
              </NoticeBox>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};

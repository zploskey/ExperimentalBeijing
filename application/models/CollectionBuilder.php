<?php
/**
 * @version $Id$
 * @copyright Center for History and New Media, 2009
 * @license http://www.gnu.org/licenses/gpl-3.0.txt
 * @package Omeka
 * @subpackage Models
 */
 
/**
 * Build a collection.
 *
 * @package Omeka
 * @subpackage Models
 * @copyright Center for History and New Media, 2009
 */
class CollectionBuilder extends Omeka_Record_Builder
{
    protected $_settableProperties = array(
        'name', 
        'description', 
        'public', 
        'featured',
        'owner_id'
    );
    
    protected $_recordClass = 'Collection';
    
    /**
     * Add collectors associated with the collection.
     */
    protected function _beforeBuild()
    {
        $metadata = $this->getRecordMetadata();
        if (array_key_exists('collectors', $metadata)) {
            $record = $this->getRecord();
            foreach($metadata['collectors'] as $collector) {
                $record->addCollector($collector);
            }
        }
    }
}
